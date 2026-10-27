import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../../build/src/api.js";
import { isMethodSafeLoop } from "../../build/src/passes/lower-statements.js";
import { repositoryRoot } from "../repository.mjs";

// GGCONV-REG-023: global field symbols typed generically (TYPE data, any,
// STANDARD TABLE, ANY TABLE) were rejected outright, and one bound in a FORM
// and used in another had no binding to convert (GGCONV-E515). LOOP AT itab[]
// and LOOP AT <table> INTO <wa> were taken for implicit header-line loops
// although their targets are explicit (GGCONV-E516). See
// fixtures/REGRESSIONS.md; the generated behavior test runs the fixture.

const fixture = (name) => fs.readFile(path.join(repositoryRoot, "converter", "test", "fixtures", name), "utf8");
const errors = (result, ...codes) => result.diagnostics.filter((item) => codes.includes(item.code));
const method = (source, name) => new RegExp(`METHOD ${name.replace(/[~]/g, "\\~")}\\.[\\s\\S]*?ENDMETHOD\\.`).exec(source)?.[0] ?? "";

async function convertFixture() {
  return convertProgram({
    source: await fixture("regression_field_symbols.prog.abap.txt"),
    filename: "zreg_field_symbols.prog.abap",
    transactionCode: "ZREGFSYM",
    resolveInclude: async (name) => ({
      zreg_field_symbols_top: await fixture("regression_field_symbols_top.incl.abap.txt"),
      zreg_field_symbols_forms: await fixture("regression_field_symbols_forms.incl.abap.txt"),
    }[name]),
  });
}

test("generic and LIKE LINE OF field symbols declared in an include are declared in the methods using them", async () => {
  const result = await convertFixture();
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E515", "GGCONV-E516", "GGCONV-E202", "GGCONV-E205"), []);
  assert.deepEqual(result.reportIR.safeFieldSymbols, [
    "GS_PROD_ORD_LIST", "GT_ALV_DYN_TABLE", "GT_DYN_TABLE", "GT_ITAB", "GT_TABLE", "GV_ALV_LINE", "GV_LINE",
    "LS_PROD_ORD_PICK_LIST", "LT_DATA", "LT_TABLE", "LV_DATA", "LV_FIELD", "LV_LINE", "STRUC",
  ]);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
  const start = method(result.classSource, "zif_gg_report_v1~start_of_selection");
  for (const declaration of [
    "FIELD-SYMBOLS <lv_data> TYPE data.",
    "FIELD-SYMBOLS <lv_field> TYPE any.",
    "FIELD-SYMBOLS <gt_itab> TYPE STANDARD TABLE.",
    "FIELD-SYMBOLS <gt_table> TYPE ANY TABLE.",
    "FIELD-SYMBOLS <gt_alv_dyn_table> TYPE STANDARD TABLE.",
    "FIELD-SYMBOLS <gs_prod_ord_list> LIKE LINE OF gt_prod_ord_list.",
    "FIELD-SYMBOLS <struc> TYPE any.",
    "FIELD-SYMBOLS <lt_data> TYPE any.",
  ]) assert.ok(start.includes(declaration), declaration);
  // Each method declares only the field symbols it uses.
  assert.doesNotMatch(start, /<gv_line>|<gt_dyn_table>|<gv_alv_line>/);
  assert.match(method(result.classSource, "form_show_dynamic"), /FIELD-SYMBOLS <gt_dyn_table> TYPE STANDARD TABLE\.\n\s+FIELD-SYMBOLS <gv_alv_line> TYPE any\./);
});

test("a global field symbol bound in one FORM and used in another keeps its binding in the class", async () => {
  const result = await convertFixture();
  const source = result.classSource;
  // Only the field symbols some method uses without binding them first.
  assert.deepEqual(Object.keys(result.reportIR.fieldSymbolReferences), ["GS_PROD_ORD_LIST", "GT_DYN_TABLE", "GV_LINE"]);
  assert.match(source, /DATA mr_ggconv_gt_dyn_table TYPE REF TO data\./);
  assert.doesNotMatch(source, /mr_ggconv_lv_field|mr_ggconv_gv_alv_line/);

  // The FORM binding it hands the binding over, and takes none first.
  const build = method(source, "form_build_dynamic");
  assert.match(build, /ASSIGN gr_table->\* TO <gt_dyn_table>\.\n\s+IF <gt_dyn_table> IS ASSIGNED\.\n\s+GET REFERENCE OF <gt_dyn_table> INTO mr_ggconv_gt_dyn_table\.\n\s+ENDIF\./);
  assert.doesNotMatch(build, /lv_ggconv_subrc/);

  // The FORM using it takes the binding over before its first statement,
  // keeping sy-subrc.
  assert.match(method(source, "form_fill_dynamic"), /DATA lv_ggconv_subrc TYPE sy-subrc\.\n\s+lv_ggconv_subrc = sy-subrc\.\n\s+IF mr_ggconv_gt_dyn_table IS BOUND\.\n\s+ASSIGN mr_ggconv_gt_dyn_table->\* TO <gt_dyn_table>\.\n\s+ELSE\.\n\s+UNASSIGN <gt_dyn_table>\.\n\s+ENDIF\.\n\s+IF mr_ggconv_gv_line IS BOUND\.[\s\S]*?sy-subrc = lv_ggconv_subrc\.\n\s+ASSIGN COMPONENT 'ID' OF STRUCTURE <gv_line> TO <lv_field>\./);

  // UNASSIGN drops the binding for every method.
  assert.match(method(source, "form_release_order"), /UNASSIGN <gs_prod_ord_list>\.\n\s+CLEAR mr_ggconv_gs_prod_ord_list\./);

  // The event takes the binding over again after a PERFORM that may change
  // it, and only after one.
  const start = method(source, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /form_bind_order\( io_session = io_session \)\.\n\s+lv_ggconv_subrc = sy-subrc\.\n\s+IF mr_ggconv_gs_prod_ord_list IS BOUND\./);
  assert.match(start, /form_release_order\( io_session = io_session \)\.\n\s+lv_ggconv_subrc = sy-subrc\./);
  assert.match(start, /form_pick_list\( io_session = io_session \)\.\n\s+form_dynamic_into\( io_session = io_session \)\./);
  assert.equal(start.match(/lv_ggconv_subrc = sy-subrc\./g).length, 3);

  // A local class reaches the binding through its owner.
  const helper = result.helperSources.map((item) => item.source).join("\n");
  assert.match(method(helper, "current_qty"), /ASSIGN mo_owner->mr_ggconv_gs_prod_ord_list->\* TO <gs_prod_ord_list>\.[\s\S]*rv_qty = <gs_prod_ord_list>-qty\./);
});

test("LOOP ... ASSIGNING hands each row's binding over inside the loop", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zfs_loop_keep.",
      "DATA gt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
      "FIELD-SYMBOLS <gv_row> TYPE i.",
      "START-OF-SELECTION.",
      "  gt_rows = VALUE #( ( 1 ) ( 2 ) ).",
      "  PERFORM last.",
      "  WRITE <gv_row>.",
      "FORM last.",
      "  LOOP AT gt_rows[] ASSIGNING <gv_row>.",
      "  ENDLOOP.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zfs_loop_keep.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(method(result.classSource, "form_last"), /LOOP AT gt_rows\[\] ASSIGNING <gv_row>\.\n\s+IF <gv_row> IS ASSIGNED\.\n\s+GET REFERENCE OF <gv_row> INTO mr_ggconv_gv_row\.\n\s+ENDIF\.\n\s+ENDLOOP\./);
});

test("LOOP AT itab[] and LOOP AT <table> INTO <wa> keep their explicit targets", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zfs_loops.",
      "TYPES: BEGIN OF ty_pick, id TYPE i, END OF ty_pick.",
      "START-OF-SELECTION.",
      "  PERFORM run.",
      "FORM run.",
      "  DATA lt_prod_ord_pick_list TYPE STANDARD TABLE OF ty_pick WITH DEFAULT KEY.",
      "  DATA lt_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.",
      "  DATA lv_work TYPE string.",
      "  FIELD-SYMBOLS <ls_prod_ord_pick_list> LIKE LINE OF lt_prod_ord_pick_list.",
      "  FIELD-SYMBOLS: <lt_table> TYPE ANY TABLE,",
      "                 <lv_line> TYPE any.",
      "  LOOP AT lt_prod_ord_pick_list[] ASSIGNING <ls_prod_ord_pick_list>.",
      "    <ls_prod_ord_pick_list>-id = 1.",
      "  ENDLOOP.",
      "  LOOP AT lt_prod_ord_pick_list[] ASSIGNING <ls_prod_ord_pick_list>.",
      "    WRITE / <ls_prod_ord_pick_list>-id.",
      "  ENDLOOP.",
      "  ASSIGN lt_rows TO <lt_table>.",
      "  ASSIGN lv_work TO <lv_line>.",
      "  LOOP AT <lt_table> INTO <lv_line>.",
      "    WRITE / lv_work.",
      "  ENDLOOP.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zfs_loops.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E515", "GGCONV-E516", "GGCONV-E202"), []);
  const form = method(result.classSource, "form_run");
  assert.equal(form.match(/LOOP AT lt_prod_ord_pick_list\[\] ASSIGNING <ls_prod_ord_pick_list>\./g).length, 2);
  assert.match(form, /LOOP AT <lt_table> INTO <lv_line>\.\n\s+lo_writer->write_field/);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

test("a LOOP is method-safe when it names a target, whatever its table operand", () => {
  const loop = (text) => isMethodSafeLoop({ kind: "Loop", text });
  for (const text of [
    "LOOP AT lt_prod_ord_pick_list[] ASSIGNING <ls_prod_ord_pick_list>.",
    "LOOP AT lt_rows[] ASSIGNING <ls_row> WHERE id = 1.",
    "LOOP AT lt_rows[] INTO ls_row.",
    "LOOP AT lt_rows[] INTO DATA(ls_row).",
    "LOOP AT <lt_table> INTO <lv_line>.",
    "LOOP AT <lt_table> INTO <ls_line>-component.",
    "LOOP AT <lt_table>[] REFERENCE INTO lr_row.",
    "LOOP AT lo_model->mt_rows[] ASSIGNING FIELD-SYMBOL(<ls_row>).",
    "LOOP AT lt_rows[] TRANSPORTING NO FIELDS WHERE id = 1.",
  ]) assert.equal(loop(text), true, text);
  // Without a target the loop reads the header line.
  for (const text of [
    "LOOP AT lt_rows.",
    "LOOP AT lt_rows[].",
    "LOOP AT lt_rows WHERE id = 1.",
    "LOOP AT <lt_table>.",
    "LOOP AT SCREEN INTO screen.",
  ]) assert.equal(loop(text), false, text);
});

test("field symbols and loops with no class equivalent are still reported", async () => {
  // An untyped or STRUCTURE-typed field symbol cannot be declared in a class.
  for (const declaration of ["FIELD-SYMBOLS <ls_row>.", "FIELD-SYMBOLS <ls_row> STRUCTURE gs_row DEFAULT gs_row."]) {
    const result = await convertProgram({
      source: `REPORT zfs_untyped.\nDATA gs_row TYPE i.\n${declaration}\nSTART-OF-SELECTION.\n  ASSIGN gs_row TO <ls_row>.\n  WRITE <ls_row>.`,
      filename: "zfs_untyped.prog.abap",
      mode: "partial",
    });
    assert.ok(errors(result, "GGCONV-E515").some((item) => item.message === "field-symbol declarations require method-local binding analysis"), declaration);
  }
  // A global bound in a FORM through a dynamic ASSIGN only, which is omitted.
  const dynamic = await convertProgram({
    source: "REPORT zfs_dynamic.\nDATA gv_name TYPE string VALUE 'GV_NAME'.\nFIELD-SYMBOLS <gv_any> TYPE any.\nSTART-OF-SELECTION.\n  PERFORM bind.\n  WRITE <gv_any>.\nFORM bind.\n  ASSIGN (gv_name) TO <gv_any>.\nENDFORM.",
    filename: "zfs_dynamic.prog.abap",
    mode: "partial",
  });
  assert.ok(errors(dynamic, "GGCONV-E515").some((item) => item.construct.startsWith("FIELD-SYMBOLS <gv_any>")));
  assert.deepEqual(dynamic.reportIR.fieldSymbolReferences, {});
  // A loop over a table without a header line, and without a target.
  const implicit = await convertProgram({
    source: "REPORT zfs_implicit.\nDATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.\nSTART-OF-SELECTION.\n  LOOP AT lt_rows[].\n  ENDLOOP.",
    filename: "zfs_implicit.prog.abap",
    mode: "partial",
  });
  assert.ok(errors(implicit, "GGCONV-E516").some((item) => item.message.includes("implicit-header-table LOOP")));
});
