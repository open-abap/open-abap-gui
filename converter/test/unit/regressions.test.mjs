import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { convertProgram, undeclaredFieldSymbols } from "../../src/api.mjs";
import { repositoryRoot } from "../repository.mjs";

const fixture = (name) => fs.readFile(path.join(repositoryRoot, "converter", "test", "fixtures", name), "utf8");

test("regression fixture keeps nested continuation branch context", async () => {
  const result = await convertProgram({
    source: await fixture("regression_nested_continuation.abap.txt"),
    filename: "regression_nested_continuation.prog.abap",
    transactionCode: "ZREGNEST",
  });
  assert.equal(result.supported, true);
  assert.equal(result.diagnostics.some((item) => item.code === "GGCONV-E402"), false);
  assert.match(result.classSource, /after conditional/);
  assert.doesNotMatch(result.classSource, /sibling branch/);
});

test("regression fixture keeps report-only loop legality explicit", async () => {
  const result = await convertProgram({
    source: await fixture("regression_implicit_loop.abap.txt"),
    filename: "regression_implicit_loop.prog.abap",
    mode: "partial",
  });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E516" && item.message.includes("implicit-header-table LOOP")));
  assert.match(result.classSource, /TODO GGCONV-E501/);
});

test("regression fixture keeps row-typed field symbols bound by LOOP and READ TABLE", async () => {
  const result = await convertProgram({
    source: await fixture("regression_field_symbol_row.abap.txt"),
    filename: "regression_field_symbol_row.prog.abap",
    transactionCode: "ZREGFSROW",
  });
  assert.equal(result.supported, true);
  assert.deepEqual(result.reportIR.safeFieldSymbols, ["LS_FOUND", "LS_PACKAGE"]);
  // Both the declarations and the statements that use them are emitted.
  assert.match(result.classSource, /FIELD-SYMBOLS <ls_package> LIKE LINE OF gt_packages\./);
  assert.match(result.classSource, /FIELD-SYMBOLS <ls_found> TYPE LINE OF gt_packages\./);
  assert.match(result.classSource, /LOOP AT gt_packages ASSIGNING <ls_package>\./);
  assert.match(result.classSource, /READ TABLE gt_packages ASSIGNING <ls_found> INDEX 1\./);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

test("regression fixture omits uses of a field symbol whose binding cannot be lowered", async () => {
  const result = await convertProgram({
    source: await fixture("regression_field_symbol_dynamic.abap.txt"),
    filename: "regression_field_symbol_dynamic.prog.abap",
    mode: "partial",
  });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E515"));
  // The dynamic ASSIGN cannot be lowered, so neither the declaration nor any
  // use of <lv_parameters> may reach the generated class.
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E205"));
  assert.match(result.classSource, /TODO GGCONV-E515: statement omitted, field symbol <lv_parameters> has no convertible binding: gv_text = <lv_parameters>\./);
  assert.match(result.classSource, /TODO GGCONV-E515: statement omitted, field symbol <lv_parameters> has no convertible binding: CLEAR <lv_parameters>\./);
  for (const line of result.classSource.split("\n")) {
    if (line.trimStart().startsWith("*")) continue;
    assert.doesNotMatch(line, /<lv_parameters>/);
  }
  // Statements that do not depend on the field symbol still convert.
  assert.match(result.classSource, /write_field\(.*gv_text/);
});

test("the post-emit gate reports field symbols used without a declaration", () => {
  // The shape the parser validation behind GGCONV-E202 accepts but activation
  // rejects: a surviving use whose declaration was dropped.
  assert.deepEqual(undeclaredFieldSymbols([
    "CLASS zcl_gap IMPLEMENTATION.",
    "  METHOD run.",
    "* FIELD-SYMBOLS <lv_commented> TYPE string.",
    "    LOOP AT gt_rows ASSIGNING <ls_row>.",
    "      WRITE <lv_commented>.",
    "    ENDLOOP.",
    "  ENDMETHOD.",
    "ENDCLASS.",
  ].join("\n")), [["LS_ROW", 4], ["LV_COMMENTED", 5]]);

  // Declared inline, in a chain that wraps, and inside a literal.
  assert.deepEqual(undeclaredFieldSymbols([
    "METHOD run.",
    "  FIELD-SYMBOLS: <ls_a> TYPE ty_row,",
    "                 <ls_b> TYPE ty_row.",
    "  LOOP AT gt_rows ASSIGNING FIELD-SYMBOL(<ls_c>).",
    "    lv_html = '<b> markup </b>'.",
    "    lv_x = <ls_a>-id + <ls_b>-id + <ls_c>-id.",
    "  ENDLOOP.",
    "ENDMETHOD.",
  ].join("\n")), []);
});

test("resolves abapGit repository-layout includes without a custom resolver", async () => {
  const repository = path.join(repositoryRoot, "converter", "test", "fixtures", "repository");
  const main = path.join(repository, "src", "zrepo_main.prog.abap");
  // `<name>.prog.abap` beside the parent is how abapGit serialises an INCLUDE
  // program; the second one only resolves through the search path.
  const result = await convertProgram({
    source: await fs.readFile(main, "utf8"),
    filename: main,
    includePaths: [path.join(repository, "shared")],
    transactionCode: "ZREPOMAIN",
  });
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E102"), JSON.stringify(result.diagnostics));
  assert.equal(result.supported, true);
  assert.match(result.classSource, /local include/);
  assert.match(result.classSource, /shared include/);

  const withoutSearchPath = await convertProgram({
    source: await fs.readFile(main, "utf8"),
    filename: main,
    transactionCode: "ZREPOMAIN",
    mode: "partial",
  });
  const unresolved = withoutSearchPath.diagnostics.filter((item) => item.code === "GGCONV-E102");
  assert.equal(unresolved.length, 1);
  assert.match(unresolved[0].message, /zrepo_shared_f02/);
});

test("source hash does not depend on where an include was found", async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-include-hash-"));
  try {
    const convertFrom = async (folder, include) => {
      await fs.mkdir(path.join(root, folder), { recursive: true });
      await fs.writeFile(path.join(root, folder, "zhash_top.prog.abap"), include);
      const result = await convertProgram({
        source: "REPORT zhash.\nINCLUDE zhash_top.\nSTART-OF-SELECTION.\nWRITE gv_text.\n",
        filename: "src/zhash.prog.abap",
        includePaths: [path.join(root, folder)],
      });
      assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E102"), JSON.stringify(result.diagnostics));
      return result.manifest.sourceHash;
    };
    const include = "DATA gv_text TYPE string VALUE 'x'.\n";
    const first = await convertFrom("checkout-a", include);
    assert.equal(await convertFrom(path.join("elsewhere", "checkout-b"), include), first);
    assert.notEqual(await convertFrom("checkout-c", "DATA gv_text TYPE string VALUE 'y'.\n"), first);
  } finally {
    await fs.rm(root, { recursive: true, force: true });
  }
});

// SCREEN-INVISIBLE masks the content of a field that stays on the screen and is
// the only way a classic report models a password entry; SCREEN-ACTIVE = 0 is
// what removes a field. The dynpro branch used to map INVISIBLE onto no_display,
// which hid the field instead of masking it.
test("regression fixture maps SCREEN-INVISIBLE to password in dynpro modules", async () => {
  const result = await convertProgram({
    source: await fixture("regression_screen_invisible.prog.abap.txt"),
    filename: "regression_screen_invisible.prog.abap",
    transactionCode: "ZREGINVIS",
    dynproMetadata: {
      initialScreen: "0100",
      screens: [{ number: "0100", title: "Invisible", elements: [{ kind: "output", name: "GV_COUNTER" }] }],
      flowLogic: [{ screen: "0100", pbo: [{ name: "STATUS_0100" }] }],
    },
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /<ls_state>-password = abap_true\./);
  assert.match(result.classSource, /<ls_state>-visible = abap_false\./);
  assert.doesNotMatch(result.classSource, /no_display/);
});

test("regression fixture emits dynpro state helpers", async () => {
  const result = await convertProgram({
    source: await fixture("regression_dynpro_state.prog.abap.txt"),
    filename: "regression_dynpro_state.prog.abap",
    dynproMetadata: {
      initialScreen: "0100",
      screens: [{ number: "0100", title: "State", elements: [{ kind: "output", name: "GV_COUNTER" }] }],
      flowLogic: [{ screen: "0100", pbo: [{ name: "STATUS_0100" }], pai: [{ name: "USER_COMMAND_0100" }] }],
      statuses: { "0100": { status: "STATE", activeUcomm: ["NEXT", "BACK"] } },
    },
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /METHOD zif_gg_dynpro_v1~process_output_module\./);
  assert.match(result.classSource, /gv_counter = CONV #\(/);
  assert.match(result.classSource, /value = CONV string\( gv_counter \)/);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});
