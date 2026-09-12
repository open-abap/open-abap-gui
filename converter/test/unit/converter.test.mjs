import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../../src/api.mjs";
import { dynamicWriteOperand } from "../../src/passes/lower-statements.mjs";
import { repositoryRoot } from "../repository.mjs";

const fixture = (name) => fs.readFile(path.join(repositoryRoot, "scaffold", "examples", name), "utf8");
const compositeFixture = (name) => fs.readFile(path.join(repositoryRoot, "converter", "test", "fixtures", name), "utf8");

test("emits a valid class for empty and implicit-start reports", async () => {
  const empty = await convertProgram({ source: "REPORT zempty.\n", filename: "zempty.prog.abap" });
  assert.equal(empty.supported, true);
  assert.match(empty.classSource, /METHOD zif_gg_report_v1~start_of_selection\./);

  const implicit = await convertProgram({ source: "REPORT zimplicit.\nWRITE 'implicit'.\n", filename: "zimplicit.prog.abap" });
  assert.equal(implicit.supported, true);
  assert.match(implicit.classSource, /METHOD zif_gg_report_v1~start_of_selection\.[\s\S]*implicit/);
});

test("keeps pre-event executable statements in the implicit start event", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zimplicit_init.",
      "DATA gv_value TYPE i.",
      "gv_value = 1.",
      "START-OF-SELECTION.",
      "WRITE gv_value.",
    ].join("\n"),
    filename: "zimplicit_init.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.deepEqual(result.reportIR.events.start_of_selection.map((item) => item.kind), ["Move", "Write"]);
  assert.match(result.classSource, /METHOD zif_gg_report_v1~start_of_selection\.[\s\S]*gv_value = 1\.[\s\S]*write_field/);
  assert.match(result.classSource, /METHOD zif_gg_report_v1~load_of_program\.\s+RETURN\./);
});

test("keeps explicit load initialization in load_of_program without relocating pre-event code", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zexplicit_load.",
      "DATA gv_value TYPE i.",
      "gv_value = 1.",
      "LOAD-OF-PROGRAM.",
      "gv_value = 2.",
      "INITIALIZATION.",
      "gv_value = 3.",
      "START-OF-SELECTION.",
      "WRITE gv_value.",
    ].join("\n"),
    filename: "zexplicit_load.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.deepEqual(result.reportIR.events.load_of_program.map((item) => item.kind), ["Move"]);
  assert.deepEqual(result.reportIR.events.start_of_selection.map((item) => item.kind), ["Move", "Write"]);
  assert.match(result.classSource, /METHOD zif_gg_report_v1~load_of_program\.[\s\S]*gv_value = 2\./);
  assert.match(result.classSource, /METHOD zif_gg_report_v1~start_of_selection\.[\s\S]*gv_value = 1\.[\s\S]*write_field/);
});

test("converts a basic report deterministically", async () => {
  const source = await fixture("zgg_ex_001.prog.abap");
  const first = await convertProgram({ source, filename: "zgg_ex_001.prog.abap" });
  const second = await convertProgram({ source, filename: "zgg_ex_001.prog.abap" });
  assert.equal(first.supported, true);
  assert.equal(first.classSource, second.classSource);
  assert.match(first.classSource, /CLASS zcl_gg_ex_001 DEFINITION/);
  assert.match(first.classSource, /write_field/);
  assert.equal(first.reportIR.capabilities.find((item) => item.kind === "Write")?.loweringRule, "list-write");
  assert.equal(first.manifest.sourceHash, second.manifest.sourceHash);
  assert.deepEqual(first.sourceMap, second.sourceMap);
  assert.equal(first.sourceMap[0].outputStart.line > 0, true);
  assert.equal(first.manifest.sourceToOutput.start_of_selection, "ZCL_GG_EX_001~start_of_selection");
});

test("lowers a selection parameter into a typed screen definition", async () => {
  const source = await fixture("zgg_ex_015.prog.abap");
  const result = await convertProgram({ source, filename: "zgg_ex_015.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /add_parameter/);
  assert.match(result.classSource, /name = 'P_CARR'/);
  assert.match(result.classSource, /it_values\[ name = 'P_CARR' \]/);
  assert.match(result.classSource, /DATA mv_p_carr TYPE string/);
});

test("does not lift selection-screen layout elements into report state", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zlayout.",
      "SELECTION-SCREEN COMMENT /1(30) TEXT-001.",
      "SELECTION-SCREEN SKIP 1.",
      "PARAMETERS p_value TYPE c.",
    ].join("\n"),
    filename: "zlayout.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /DATA mv_cmt1/);
  assert.match(result.classSource, /DATA mv_p_value TYPE string/);
});

test("applies supplied text-pool labels and warns for unresolved labels", async () => {
  const source = await fixture("zgg_ex_015.prog.abap");
  const resolved = await convertProgram({ source, filename: "zgg_ex_015.prog.abap", textPool: "TEXT-P_CARR = Carrier\n" });
  assert.match(resolved.classSource, /text = 'Carrier'/);
  assert.equal(resolved.diagnostics.some((item) => item.code === "GGCONV-W101"), false);

  const fallback = await convertProgram({ source, filename: "zgg_ex_015.prog.abap" });
  assert.ok(fallback.diagnostics.some((item) => item.code === "GGCONV-W101"));
});

test("strict mode reports an unsupported program kind without emitting", async () => {
  const result = await convertProgram({ source: "PROGRAM zpool.\nMODULE x INPUT.\nENDMODULE.\n", filename: "zpool.prog.abap" });
  assert.equal(result.supported, false);
  assert.equal(result.classSource, undefined);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E502"));
});

test("partial mode marks unsupported statements instead of dropping them", async () => {
  const result = await convertProgram({ source: "REPORT zpartial.\nCALL FUNCTION 'X'.\n", filename: "zpartial.prog.abap", mode: "partial" });
  assert.equal(result.supported, false);
  assert.match(result.classSource, /TODO GGCONV/);
});

test("safe partial strategy emits a compilable diagnostic skeleton", async () => {
  const result = await convertProgram({
    source: "REPORT zpartial_skeleton.\nCLASS lcl_local DEFINITION.\nENDCLASS.\nCALL FUNCTION 'X'.\n",
    filename: "zpartial_skeleton.prog.abap",
    mode: "partial",
    partialStrategy: "skeleton",
  });
  assert.equal(result.supported, false);
  assert.match(result.classSource, /Partial conversion preview/);
  assert.match(result.classSource, /TODO GGCONV-E305/);
  assert.doesNotMatch(result.classSource, /(?:^|\n)CLASS lcl_local DEFINITION/);
  assert.equal(result.manifest.partialStrategy, "skeleton");
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E202"));
});

test("reports unsupported WRITE additions individually", async () => {
  const result = await convertProgram({ source: "REPORT zwrite.\nWRITE 'x' COLOR 4.\n", filename: "zwrite.prog.abap", mode: "partial" });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E501"));
  assert.match(result.classSource, /TODO GGCONV-E501: unsupported WRITE formatting/);
});

test("keeps logical-database GET events outside the converter scope", async () => {
  const result = await convertProgram({
    source: "REPORT zlogical_database.\nGET spfli.\n",
    filename: "zlogical_database.prog.abap",
  });
  assert.equal(result.supported, false);
  assert.equal(result.classSource, undefined);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E501"));
});

test("marks dynamic WRITE calls before lowering", () => {
  const dynamic = dynamicWriteOperand({kind: "Write", text: "WRITE (get_target( ))."});
  assert.equal(dynamic?.supported, false);
});

test("lowers dynamic WRITE substring operands without treating them as calls", async () => {
  const result = await convertProgram({
    source: "REPORT zdynamic_write_substring.\nDATA gv_name TYPE string.\nWRITE (gv_name(10)).\n",
    filename: "zdynamic_write_substring.prog.abap",
    transactionCode: "ZDWSUB",
    mode: "partial",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /dynamic WRITE operand/);
  assert.match(result.classSource, /CASE gv_name\(10\)\./);
});

test("evaluates unsupported dynamic WRITE operands once before guarded fallback assignment", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdynamic_write_fallback.",
      "DATA gv_name TYPE string.",
      "DATA gv_offset TYPE i.",
      "START-OF-SELECTION.",
      "  WRITE / (gv_name+gv_offset(8)).",
    ].join("\n"),
    filename: "zdynamic_write_fallback.prog.abap",
    className: "ZDYNWFALLBACK",
    transactionCode: "ZDYNWFALL",
    mode: "partial",
  });
  assert.equal(result.supported, false);
  assert.match(result.classSource, /DATA lv_ggconv_dynamic_name TYPE string\.[\s\S]*lv_ggconv_dynamic_name = gv_name\+gv_offset\(8\)\./);
  assert.match(result.classSource, /ASSIGN \(lv_ggconv_dynamic_name\) TO <ggconv_dynamic_value>\./);
  assert.equal((result.classSource.match(/gv_name\+gv_offset\(8\)/g) ?? []).length, 1);
  assert.match(result.classSource, /TODO GGCONV-E501: dynamic WRITE target/);
});

test("lowers balanced dynamic WRITE name expressions without duplicating them", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdynamic_write_expression.",
      "DATA gv_prefix TYPE string.",
      "DATA gv_value TYPE string.",
      "START-OF-SELECTION.",
      "  gv_prefix = 'XGV_VALUE'.",
      "  gv_value = 'expression'.",
      "  WRITE / (gv_prefix+1(8)).",
    ].join("\n"),
    filename: "zdynamic_write_expression.prog.abap",
    className: "ZDYNWRITEEXPR",
    transactionCode: "ZDYNWEXPR",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /CASE gv_prefix\+1\(8\)\./);
  assert.equal((result.classSource.match(/gv_prefix\+1\(8\)/g) ?? []).length, 1);
  assert.match(result.classSource, /write_field\( VALUE #\( text = \|\{ gv_value \}\|/);
});

test("lowers dynamic WRITE variable names with a guarded known-target dispatch", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdynamic_write_supported.",
      "DATA gv_name TYPE string.",
      "DATA gv_value TYPE string.",
      "START-OF-SELECTION.",
      "  gv_name = 'GV_VALUE'.",
      "  WRITE / (gv_name).",
    ].join("\n"),
    filename: "zdynamic_write_supported.prog.abap",
    transactionCode: "ZDYNWRITE",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /dynamic WRITE operand/);
  assert.match(result.classSource, /CASE gv_name\.[\s\S]*WHEN 'GV_VALUE'\.[\s\S]*write_field\( VALUE #\( text = \|\{ gv_value \}\| placement = VALUE #\( new_line = abap_true \) \) \)\.[\s\S]*WHEN OTHERS\.[\s\S]*ENDCASE\./);
});

test("keeps lowered dynamic WRITE expression exceptions inside their source TRY block", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdynamic_write_exception.",
      "DATA gv_prefix TYPE string.",
      "DATA gv_value TYPE string.",
      "START-OF-SELECTION.",
      "TRY.",
      "  WRITE / (gv_prefix+1(8)).",
      "CATCH cx_sy_range_out_of_bounds.",
      "  gv_value = 'range-error'.",
      "ENDTRY.",
    ].join("\n"),
    filename: "zdynamic_write_exception.prog.abap",
    transactionCode: "ZDYNWEXC",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /TRY\.[\s\S]*CASE gv_prefix\+1\(8\)\.[\s\S]*CATCH cx_sy_range_out_of_bounds\.[\s\S]*ENDTRY\./);
});

test("diagnoses unrepresentable desktop GUI operations", async () => {
  const result = await convertProgram({
    source: "REPORT zdesktop.\nCALL METHOD cl_gui_frontend_services=>execute.\n",
    filename: "desktop.prog.abap",
    mode: "partial",
  });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E501"));
  assert.match(result.classSource, /TODO GGCONV-E501/);
});

test("diagnoses dynamic PERFORM instead of emitting a guessed call", async () => {
  const result = await convertProgram({ source: "REPORT zperform.\nPERFORM (lv_form).\n", filename: "zperform.prog.abap", mode: "partial" });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E401"));
  assert.match(result.classSource, /TODO GGCONV-E401/);

  const dynamicCall = await convertProgram({ source: "REPORT zdyncall.\nCALL METHOD (lv_method).\n", filename: "zdyncall.prog.abap", mode: "partial" });
  assert.equal(dynamicCall.supported, false);
  assert.ok(dynamicCall.diagnostics.some((item) => item.code === "GGCONV-E501"));
  assert.match(dynamicCall.classSource, /TODO GGCONV-E501/);
});

test("converts local FORM parameters to typed methods and PERFORM calls", async () => {
  const source = [
    "REPORT zform.",
    "DATA gv_result TYPE i.",
    "FORM add USING iv_left TYPE i CHANGING cv_result TYPE i.",
    "  cv_result = iv_left.",
    "ENDFORM.",
    "START-OF-SELECTION.",
    "PERFORM add USING 1 CHANGING gv_result.",
  ].join("\n");
  const result = await convertProgram({ source, filename: "zform.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /METHODS form_add[\s\S]*IMPORTING[\s\S]*io_session\s+TYPE REF TO zif_gg_session_v1[\s\S]*iv_left\s+TYPE i[\s\S]*CHANGING[\s\S]*cv_result\s+TYPE i/);
  assert.match(result.classSource, /form_add\([\s\S]*EXPORTING[\s\S]*io_session\s*=\s*io_session[\s\S]*iv_left\s*=\s*1[\s\S]*CHANGING[\s\S]*cv_result\s*=\s*gv_result/);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

test("normalizes BOM and newline variants before hashing", async () => {
  const lf = "REPORT znewline.\nSTART-OF-SELECTION.\nWRITE 'ok'.\n";
  const crlf = `\uFEFF${lf.replaceAll("\n", "\r\n")}`;
  const first = await convertProgram({ source: lf, filename: "znewline.prog.abap" });
  const second = await convertProgram({ source: crlf, filename: "znewline.prog.abap" });
  assert.equal(first.manifest.sourceHash, second.manifest.sourceHash);
  assert.equal(first.classSource, second.classSource);
  assert.equal(first.sourceMap[0].start.line, 3);
  assert.deepEqual(first.sourceMap, second.sourceMap);
});

test("preserves UTF-8 literals and comments through the parser adapter", async () => {
  const result = await convertProgram({
    source: "REPORT zutf8.\n* Grüße 世界\nSTART-OF-SELECTION.\nWRITE 'Grüße 世界'.\n",
    filename: "zutf8.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /Grüße 世界/);
  assert.match(result.classSource, /\* Grüße 世界/);
});

test("reports parser locations and include cycles", async () => {
  const malformed = await convertProgram({ source: "REPORT zbad.\nTHIS IS NOT ABAP.\n", filename: "zbad.prog.abap" });
  assert.equal(malformed.supported, false);
  assert.equal(malformed.diagnostics.find((item) => item.code === "GGCONV-E201").start.line, 2);

  const cycle = await convertProgram({
    source: "REPORT zcycle.\nINCLUDE one.\n",
    filename: "zcycle.prog.abap",
    resolveInclude: async (name) => name === "one" ? "INCLUDE two.\n" : "INCLUDE one.\n",
  });
  assert.ok(cycle.diagnostics.some((item) => item.code === "GGCONV-E104"));
});

test("converts composite fixtures with nested includes, routines, and database access", async () => {
  const nested = await convertProgram({
    source: await compositeFixture("composite_nested_includes.abap.txt"),
    filename: "zcomposite_nested.prog.abap",
    resolveInclude: async (name) => ({
      zcomposite_top: "DATA gv_total TYPE i.\nINCLUDE zcomposite_form.",
      zcomposite_form: "FORM add_value USING iv_value TYPE i CHANGING cv_total TYPE i.\n  ADD iv_value TO cv_total.\nENDFORM.",
    }[name]),
  });
  assert.equal(nested.supported, true);
  assert.match(nested.classSource, /METHOD form_add_value/);
  assert.match(nested.classSource, /PERFORM|form_add_value/);

  const localClass = await convertProgram({
    source: await compositeFixture("composite_local_class.abap.txt"),
    filename: "zcomposite_local_class.prog.abap",
    mode: "partial",
  });
  assert.ok(localClass.diagnostics.some((item) => item.code === "GGCONV-E305"));
  assert.match(localClass.classSource, /TODO GGCONV-E305/);

  const database = await convertProgram({
    source: await compositeFixture("composite_sql_form.abap.txt"),
    filename: "zcomposite_sql_form.prog.abap",
    ddicTypes: { ZSFLIGHT: { type: "zsflight" } },
  });
  assert.equal(database.supported, true);
  assert.match(database.classSource, /SELECT \* FROM zsflight/);
  assert.match(database.classSource, /METHOD form_add_value/);
});

test("validates explicit class and transaction names", async () => {
  const result = await convertProgram({
    source: "REPORT zvalid.\nSTART-OF-SELECTION.\nWRITE 'ok'.\n",
    filename: "zvalid.prog.abap",
    className: "Z_THIS_CLASS_NAME_IS_TOO_LONG_FOR_ABAP",
    transactionCode: "not valid",
  });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E101"));
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E105"));

  const collision = await convertProgram({
    source: "REPORT zvalid.\nWRITE 'ok'.\n",
    filename: "zvalid.prog.abap",
    existingClassNames: ["ZCL_VALID"],
  });
  assert.ok(collision.diagnostics.some((item) => item.code === "GGCONV-E106"));
});

test("lowers interactive list context and keeps GET CURSOR in its list event", async () => {
  const source = await fixture("zgg_ex_047.prog.abap");
  const result = await convertProgram({ source, filename: "zgg_ex_047.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /METHOD zif_gg_list_processing_v1~at_line_selection\./);
  assert.match(result.classSource, /get_cursor\( \)[\s\S]*gv_field = ls_cursor-field/);
  assert.equal(Object.hasOwn(result.reportIR.events, "at_get"), false);
});

test("lowers resumable report transfers and captures nested selection state", async () => {
  const source = await fixture("zgg_ex_051.prog.abap");
  const result = await convertProgram({ source, filename: "zgg_ex_051.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /INTERFACES zif_gg_resumable_v1/);
  assert.match(result.classSource, /call_selection_screen/);
  assert.match(result.classSource, /mv_p_b = ct_values/);
  assert.match(result.classSource, /METHOD zif_gg_resumable_v1~resume/);
  assert.match(result.classSource, /is_resume-subrc = 0/);
  assert.ok(result.reportIR.continuations[0].liveVariables.includes("P_B"));
  assert.ok(result.scaffoldIR.continuations[0].capturedVariables.includes("mv_p_b"));
  assert.ok(result.scaffoldIR.sessionOperations.some((item) => item.kind === "dialog-call-selection-screen"));
});

test("uses explicit dynpro metadata for module-pool conversion", async () => {
  const source = await fixture("zgg_ex_058.prog.abap");
  const result = await convertProgram({
    source,
    filename: "zgg_ex_058.prog.abap",
    dynproMetadata: {
      initialScreen: "0100",
      screens: [{ number: "0100", title: "Main" }, { number: "0200", title: "Next" }],
      flowLogic: [{ screen: "0100", pai: [{ name: "USER_COMMAND_0100" }] }],
    },
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /INTERFACES zif_gg_dynpro_v1/);
  assert.equal(result.reportIR.dynproIR.kind, "dynpro-program");
  assert.match(result.classSource, /rv_screen = '0100'/);
  assert.match(result.classSource, /set_next_screen\( '0200' \)/);
  assert.match(result.classSource, /leave_to_screen\( '0000' \)/);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E502/);
});

test("keeps report IR serializable and renames generated-name collisions", async () => {
  const result = await convertProgram({
    source: "REPORT zcollision.\nDATA lo_writer TYPE i.\nSTART-OF-SELECTION.\nWRITE lo_writer.\n",
    filename: "zcollision.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.equal(result.reportIR.statements.some((statement) => Object.hasOwn(statement, "node")), false);
  assert.equal(result.manifest.identifierRenames.LO_WRITER, "mv_lo_writer");
  assert.match(result.classSource, /DATA mv_lo_writer TYPE i/);
  assert.match(result.classSource, /text = \|\{ mv_lo_writer \}\|/);
  assert.doesNotThrow(() => JSON.stringify(result.reportIR));
  assert.equal(result.scaffoldIR.kind, "scaffold-class");
  assert.doesNotThrow(() => JSON.stringify(result.scaffoldIR));
  assert.ok(result.scaffoldIR.methods.some((item) => item.name.endsWith("~start_of_selection")));
  assert.equal(result.scaffoldIR.definition.final, true);
  assert.equal(result.scaffoldIR.transaction.tcode, "ZCOLLISION");
  assert.ok(Array.isArray(result.scaffoldIR.screenBuilder.operations));
  assert.ok(result.scaffoldIR.methods.find((item) => item.name.endsWith("~start_of_selection")).operations.some((item) => item.kind === "list-write"));
});

test("preserves constants and converts static attributes to class state", async () => {
  const result = await convertProgram({
    source: "REPORT zdecl.\nCONSTANTS gc_value TYPE i VALUE 1.\nSTATICS gv_static TYPE i.\nWRITE gc_value.\n",
    filename: "zdecl.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /CONSTANTS gc_value TYPE i VALUE 1/);
  assert.match(result.classSource, /DATA gv_static TYPE i/);
  assert.match(result.classSource, /text = \|\{ gc_value \}\|/);
});

test("lowers method-local field symbols only when static binding is provable", async () => {
  const safe = await convertProgram({
    source: [
      "REPORT zfields.",
      "DATA gv_value TYPE i.",
      "START-OF-SELECTION.",
      "FIELD-SYMBOLS <value> TYPE i.",
      "ASSIGN gv_value TO <value>.",
      "<value> = 2.",
      "WRITE <value>.",
    ].join("\n"),
    filename: "zfields.prog.abap",
  });
  assert.equal(safe.supported, true);
  assert.deepEqual(safe.reportIR.safeFieldSymbols, ["VALUE"]);
  assert.match(safe.classSource, /FIELD-SYMBOLS <value> TYPE i/);
  assert.match(safe.classSource, /ASSIGN gv_value TO <value>/);
  assert.doesNotMatch(safe.classSource, /TODO GGCONV/);

  const unsafe = await convertProgram({
    source: "REPORT zfields.\nFIELD-SYMBOLS <value> TYPE any.\n",
    filename: "zfields.prog.abap",
    mode: "partial",
  });
  assert.equal(unsafe.supported, false);
  assert.ok(unsafe.diagnostics.some((item) => item.code === "GGCONV-E501"));
});

test("preserves chained and table-shaped global declarations", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdecl.",
      "DATA: gv_count TYPE i, gt_values TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
      "START-OF-SELECTION.",
      "  APPEND 1 TO gt_values.",
      "  gv_count = lines( gt_values ).",
      "  WRITE gv_count.",
    ].join("\n"),
    filename: "declarations.prog.abap",
    mode: "partial",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /gv_count/);
  assert.match(result.classSource, /gt_values/);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E501/);
});

test("preserves method-safe arithmetic and internal-table statements", async () => {
  const result = await convertProgram({
    source: [
      "REPORT ztable_ops.",
      "DATA: gv_value TYPE i, gt_values TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
      "START-OF-SELECTION.",
      "  APPEND 1 TO gt_values.",
      "  READ TABLE gt_values INTO gv_value INDEX 1.",
      "  ADD 1 TO gv_value.",
      "  INSERT gv_value INTO TABLE gt_values.",
      "  MODIFY gt_values FROM gv_value INDEX 1.",
      "  DELETE gt_values INDEX 1.",
      "  CLEAR gv_value.",
    ].join("\n"),
    filename: "table-ops.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /READ TABLE gt_values INTO gv_value INDEX 1/);
  assert.match(result.classSource, /INSERT gv_value INTO TABLE gt_values/);
  assert.match(result.classSource, /DELETE gt_values INDEX 1/);
  assert.equal(result.reportIR.capabilities.find((item) => item.kind === "Append")?.methodSafe, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E501/);
});

test("preserves structured, table, reference, and elementary type declarations", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdecl_shapes.",
      "TYPES: BEGIN OF ty_row,",
      "         id TYPE i,",
      "         text TYPE string,",
      "       END OF ty_row.",
      "DATA gs_row TYPE ty_row.",
      "DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.",
      "DATA gr_row TYPE REF TO ty_row.",
      "FORM use_local_type.",
      "  TYPES ty_local TYPE i.",
      "  DATA lv_local TYPE ty_local.",
      "  lv_local = gs_row-id.",
      "ENDFORM.",
      "START-OF-SELECTION.",
      "  gs_row-id = 1.",
      "  APPEND gs_row TO gt_rows.",
      "  PERFORM use_local_type.",
      "  WRITE lines( gt_rows ).",
    ].join("\n"),
    filename: "zdecl_shapes.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /TYPES: BEGIN OF ty_row/);
  assert.match(result.classSource, /DATA gs_row TYPE ty_row/);
  assert.match(result.classSource, /DATA gt_rows TYPE STANDARD TABLE OF ty_row/);
  assert.match(result.classSource, /DATA gr_row TYPE REF TO ty_row/);
  assert.match(result.classSource, /METHOD form_use_local_type[\s\S]*TYPES ty_local TYPE i[\s\S]*DATA lv_local TYPE ty_local/);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

test("does not duplicate WRITE operands or rewrite short-circuit conditions", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zexpression_order.",
      "DATA gt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
      "DATA gv_left TYPE i.",
      "DATA gv_right TYPE i.",
      "START-OF-SELECTION.",
      "  IF gv_left = 0 AND gv_right = lines( gt_rows ).",
      "    WRITE: gv_left, lines( gt_rows ).",
      "  ENDIF.",
    ].join("\n"),
    filename: "zexpression_order.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /IF gv_left = 0 AND gv_right = lines\( gt_rows \)\./);
  assert.equal((result.classSource.match(/text = \|\{ lines\( gt_rows \) \}\|/g) ?? []).length, 1);
  assert.ok(result.classSource.indexOf("text = |{ gv_left }|") < result.classSource.indexOf("text = |{ lines( gt_rows ) }|"));
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

test("preserves static Open SQL and diagnoses dynamic database targets", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zsql.",
      "DATA lt_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.",
      "START-OF-SELECTION.",
      "SELECT * FROM zsflight INTO TABLE @lt_flights WHERE carrid = 'LH'.",
      "LOOP AT lt_flights INTO DATA(ls_flight).",
      "  WRITE / ls_flight-carrid.",
      "ENDLOOP.",
      "INSERT zsflight FROM @lt_flights[ 1 ].",
    ].join("\n"),
    filename: "zsql.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /SELECT \* FROM zsflight INTO TABLE @lt_flights/);
  assert.match(result.classSource, /LOOP AT lt_flights INTO DATA\(ls_flight\)/);
  assert.match(result.classSource, /INSERT zsflight FROM @lt_flights/);
  assert.equal(result.reportIR.capabilities.find((item) => item.kind === "Select")?.methodSafe, true);

  const dynamic = await convertProgram({
    source: "REPORT zdynamic_sql.\nSTART-OF-SELECTION.\nSELECT * FROM (lv_table) INTO TABLE @lt_rows.",
    filename: "zdynamic_sql.prog.abap",
    mode: "partial",
  });
  assert.equal(dynamic.supported, false);
  assert.ok(dynamic.diagnostics.some((item) => item.code === "GGCONV-E501"));
});

test("diagnoses report-only method legality gaps instead of claiming support", async () => {
  const implicitLoop = await convertProgram({
    source: [
      "REPORT zimplicit_loop.",
      "DATA gt_values TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
      "START-OF-SELECTION.",
      "LOOP AT gt_values.",
      "  WRITE / gt_values.",
      "ENDLOOP.",
    ].join("\n"),
    filename: "zimplicit_loop.prog.abap",
    mode: "partial",
  });
  assert.equal(implicitLoop.supported, false);
  assert.ok(implicitLoop.diagnostics.some((item) => item.code === "GGCONV-E501" && item.message.includes("implicit-header-table LOOP")));
  assert.match(implicitLoop.classSource, /TODO GGCONV-E501: unsupported statement omitted: LOOP AT gt_values/i);

  const functionCall = await convertProgram({
    source: "REPORT zfunction_call.\nCALL FUNCTION 'Z_UNSUPPORTED'.\n",
    filename: "zfunction_call.prog.abap",
    mode: "partial",
  });
  assert.equal(functionCall.supported, false);
  assert.ok(functionCall.diagnostics.some((item) => item.code === "GGCONV-E501" && item.construct.includes("CALL FUNCTION 'Z_UNSUPPORTED'")));
  assert.match(functionCall.classSource, /TODO GGCONV-E501/);
});

test("records typed symbol read and write references", async () => {
  const result = await convertProgram({
    source: "REPORT zrefs.\nDATA gv_count TYPE i.\nPARAMETERS p_limit TYPE i.\nSTART-OF-SELECTION.\ngv_count = p_limit + 1.\nWRITE gv_count.",
    filename: "zrefs.prog.abap",
  });
  assert.deepEqual(result.reportIR.references.statements.find((item) => item.kind === "Move").writes, ["GV_COUNT"]);
  assert.ok(result.reportIR.references.statements.find((item) => item.kind === "Move").reads.includes("P_LIMIT"));
  assert.ok(result.reportIR.references.selections.some((item) => item.name === "P_LIMIT"));
});

test("resolves supplied DDIC table and field metadata", async () => {
  const result = await convertProgram({
    source: "REPORT zddic.\nTABLES zsflight.\nSELECT-OPTIONS s_carr FOR zsflight-carrid.\n",
    filename: "zddic.prog.abap",
    ddicTypes: { ZSFLIGHT: { type: "zsflight", fields: { CARRID: { type: "c", length: 3 } } } },
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /DATA zsflight TYPE zsflight/);
  assert.match(result.classSource, /name = 'S_CARR'[\s\S]*typ = 'C'[\s\S]*length = 3/);

  const missing = await convertProgram({ source: "REPORT zddic.\nTABLES zsflight.\n", filename: "zddic.prog.abap" });
  assert.equal(missing.supported, false);
  assert.ok(missing.diagnostics.some((item) => item.code === "GGCONV-E301"));
});

test("classifies non-report program kinds and rejects duplicate singleton events", async () => {
  const functionPool = await convertProgram({ source: "FUNCTION-POOL zf.\n", filename: "zf.fugr.abap" });
  assert.equal(functionPool.supported, false);
  assert.equal(functionPool.reportIR.programKind, "function-pool");
  assert.ok(functionPool.diagnostics.some((item) => item.code === "GGCONV-E102"));

  const duplicate = await convertProgram({ source: "REPORT zdup.\nSTART-OF-SELECTION.\nWRITE 'one'.\nSTART-OF-SELECTION.\nWRITE 'two'.\n", filename: "zdup.prog.abap" });
  assert.equal(duplicate.supported, false);
  assert.ok(duplicate.diagnostics.some((item) => item.code === "GGCONV-E203"));
});

test("does not emit statements after a top-level STOP", async () => {
  const source = await fixture("zgg_ex_014.prog.abap");
  const result = await convertProgram({ source, filename: "zgg_ex_014.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /stop\( \)\./);
  assert.doesNotMatch(result.classSource, /never reached/);
});

test("diagnoses duplicate routines after include expansion", async () => {
  const source = "REPORT zduproutine.\nFORM run.\nENDFORM.\nFORM run.\nENDFORM.\n";
  const result = await convertProgram({ source, filename: "zduproutine.prog.abap" });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E204"));
});

test("splits nested conditional continuations and skips sibling branches", async () => {
  const result = await convertProgram({
    source: [
      "REPORT znested.",
      "DATA gv_value TYPE i.",
      "START-OF-SELECTION.",
      "IF gv_value = 0.",
      "  IF abap_true = abap_true.",
      "    CALL SCREEN 100.",
      "    WRITE 'after inner'.",
      "  ENDIF.",
      "  WRITE 'after outer'.",
      "ELSE.",
      "  WRITE 'sibling branch'.",
      "ENDIF.",
      "WRITE 'after conditional'.",
    ].join("\n"),
    filename: "znested.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.equal(result.diagnostics.some((item) => item.code === "GGCONV-E402"), false);
  assert.match(result.classSource, /CALL SCREEN[\s\S]*END IF|call_screen[\s\S]*ENDIF\./i);
  const resume = result.classSource.match(/METHOD zif_gg_resumable_v1~resume\.[\s\S]*?ENDMETHOD\./)?.[0] ?? "";
  assert.match(resume, /after inner/);
  assert.match(resume, /after outer/);
  assert.match(resume, /after conditional/);
  assert.doesNotMatch(resume, /sibling branch/);
});

test("keeps loop and exception continuations explicitly unsupported", async () => {
  const loop = await convertProgram({ source: "REPORT zloop.\nSTART-OF-SELECTION.\nDO 2 TIMES.\n  CALL SCREEN 100.\nENDDO.\n", filename: "zloop.prog.abap" });
  assert.equal(loop.supported, false);
  assert.ok(loop.diagnostics.some((item) => item.code === "GGCONV-E402"));
});

test("marks unsupported statements instead of silently dropping them", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zunsupported_marker.",
      "START-OF-SELECTION.",
      "CALL FUNCTION 'NOT_SUPPORTED'.",
    ].join("\n"),
    filename: "zunsupported_marker.prog.abap",
    mode: "partial",
  });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E501"));
  assert.match(result.classSource, /TODO GGCONV-E501: unsupported/);
});

test("preserves method-safe exception blocks", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zexception_block.",
      "DATA gv_value TYPE i.",
      "START-OF-SELECTION.",
      "TRY.",
      "  gv_value = 1.",
      "CATCH cx_root.",
      "  gv_value = 2.",
      "CLEANUP.",
      "  CLEAR gv_value.",
      "ENDTRY.",
      "WRITE gv_value.",
    ].join("\n"),
    filename: "zexception_block.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /TRY\.[\s\S]*CATCH cx_root\.[\s\S]*CLEANUP\.[\s\S]*ENDTRY\./);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

test("preserves ordered qualified selection handlers", async () => {
  const source = [
    "REPORT zqual.",
    "PARAMETERS p_a TYPE c.",
    "PARAMETERS p_b TYPE c.",
    "AT SELECTION-SCREEN ON p_a.",
    "WRITE / 'a'.",
    "AT SELECTION-SCREEN ON p_b.",
    "WRITE / 'b'.",
  ].join("\n");
  const result = await convertProgram({ source, filename: "zqual.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /iv_name = 'P_A'[\s\S]*text = 'a'[\s\S]*iv_name = 'P_B'[\s\S]*text = 'b'/);
});

test("preserves routine-local declarations and recursive FORM calls", async () => {
  const source = [
    "REPORT zrecursive.",
    "FORM recur USING iv_n TYPE i.",
    "  DATA lv_local TYPE i.",
    "  lv_local = iv_n.",
    "  IF iv_n > 0.",
    "    PERFORM recur USING iv_n.",
    "  ENDIF.",
    "ENDFORM.",
    "START-OF-SELECTION.",
    "PERFORM recur USING 1.",
  ].join("\n");
  const result = await convertProgram({ source, filename: "zrecursive.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /METHOD form_recur[\s\S]*DATA lv_local TYPE i[\s\S]*form_recur\(/);
});

test("preserves dynamic MESSAGE operands", async () => {
  const result = await convertProgram({
    source: "REPORT zmsg.\nDATA gv_value TYPE string.\nMESSAGE i001(zmsg) WITH gv_value 'fixed'.\n",
    filename: "zmsg.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /v1 = gv_value/);
  assert.match(result.classSource, /v2 = 'fixed'/);
});

test("reports external message-class metadata requirements", async () => {
  const source = "REPORT zmsgmeta.\nMESSAGE i001(zmsg) WITH 'value'.";
  const external = await convertProgram({ source, filename: "zmsgmeta.prog.abap" });
  assert.ok(external.diagnostics.some((item) => item.code === "GGCONV-I101"));
  assert.equal(external.supported, true);

  const missing = await convertProgram({
    source,
    filename: "zmsgmeta.prog.abap",
    messageMetadata: { ZMSG: { "002": { text: "other" } } },
  });
  assert.ok(missing.diagnostics.some((item) => item.code === "GGCONV-E306"));
  assert.equal(missing.supported, false);

  const supplied = await convertProgram({
    source,
    filename: "zmsgmeta.prog.abap",
    messageMetadata: { ZMSG: { "001": { text: "Message &1" } } },
  });
  assert.equal(supplied.diagnostics.some((item) => item.code === "GGCONV-E306"), false);
});

test("emits every top-level continuation in a deterministic resume dispatcher", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zrepeat.",
      "START-OF-SELECTION.",
      "  CALL SCREEN 100.",
      "  CALL SCREEN 200.",
      "  WRITE 'done'.",
    ].join("\n"),
    filename: "zrepeat.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.equal(result.reportIR.continuations.length, 2);
  assert.match(result.classSource, /WHEN 'AFTER_0100'\./);
  assert.match(result.classSource, /WHEN 'AFTER_0200'\./);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

test("diagnoses local classes with a targeted manual-conversion message", async () => {
  const result = await convertProgram({
    source: "REPORT zlocal.\nCLASS lcl_local DEFINITION.\nENDCLASS.\nCLASS lcl_local IMPLEMENTATION.\nENDCLASS.\n",
    filename: "zlocal.prog.abap",
  });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E305"));
  assert.equal(result.reportIR.localClasses.length, 2);
});
