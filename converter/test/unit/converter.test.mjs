import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../../src/api.mjs";
import { loadDynproMetadata } from "../../src/dynpro-metadata.mjs";
import { COMPATIBILITY_FUNCTION_MODULES } from "../../src/function-modules.mjs";
import { dynamicWriteOperand } from "../../src/passes/lower-statements.mjs";
import { ACTIONABLE_DIAGNOSTIC_CODES } from "../../src/capability.mjs";
import { repositoryRoot } from "../repository.mjs";

const fixture = (name) => fs.readFile(path.join(repositoryRoot, "examples", name), "utf8");
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

test("applies report metadata text symbols to selection labels and transaction headings", async () => {
  const filename = path.join(repositoryRoot, "converter", "test", "fixtures", "text_metadata.prog.abap");
  const result = await convertProgram({
    source: await fs.readFile(filename, "utf8"),
    filename,
  });
  assert.equal(result.supported, true);
  assert.equal(result.reportIR.description, "Metadata-backed selection");
  assert.equal(result.reportIR.selections[0].elements.find((item) => item.kind === "parameter").text, "Text value");
  assert.match(result.classSource, /text = 'Text from metadata'/);
  assert.match(result.classSource, /title = 'Main block heading'/);
  assert.match(result.classSource, /text = 'Apply metadata'/);
  assert.match(result.classSource, /text = 'First tab'/);
  assert.match(result.classSource, /description = 'Metadata-backed selection'/);
  assert.equal(result.diagnostics.some((item) => item.code === "GGCONV-W101"), false);
});

test("keeps the TPOOL report title for page headings when a harness description is supplied", async () => {
  const filename = path.join(repositoryRoot, "converter", "test", "fixtures", "text_metadata.prog.abap");
  const result = await convertProgram({
    source: await fs.readFile(filename, "utf8"),
    filename,
    description: "Harness description",
  });
  assert.equal(result.reportIR.reportTitle, "Metadata-backed selection");
  assert.equal(result.reportIR.description, "Harness description");
  assert.match(result.classSource, /METHOD zif_gg_report_v1~load_of_program\.[\s\S]*set_title\( 'Metadata-backed selection' \)/);
  assert.match(result.classSource, /METHOD zif_gg_report_v1~start_of_selection\.[\s\S]*set_title\( 'Metadata-backed selection' \)/);
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
    source: "PROGRAM zpartial_skeleton.\nMODULE x INPUT.\nENDMODULE.\n",
    filename: "zpartial_skeleton.prog.abap",
    mode: "partial",
    partialStrategy: "skeleton",
  });
  assert.equal(result.supported, false);
  assert.match(result.classSource, /Partial conversion preview/);
  assert.doesNotMatch(result.classSource, /GGCONV-E305/);
  assert.doesNotMatch(result.classSource, /(?:^|\n)CLASS lcl_local DEFINITION/);
  assert.equal(result.manifest.partialStrategy, "skeleton");
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E202"));
});

test("partial conversion rejects empty generated dynpro module bodies", async () => {
  const result = await convertProgram({
    source: [
      "PROGRAM zempty_dynpro_modules.",
      "MODULE pbo OUTPUT.",
      "  CALL FUNCTION 'NOT_LOWERED'.",
      "ENDMODULE.",
      "MODULE pai INPUT.",
      "ENDMODULE.",
    ].join("\n"),
    filename: "zempty_dynpro_modules.prog.abap",
    mode: "partial",
    partialStrategy: "skeleton",
    dynproMetadata: {
      initialScreen: "0100",
      screens: [{number: "0100"}],
      flowLogic: [{
        screen: "0100",
        pbo: [{name: "PBO"}],
        pai: [{name: "PAI"}],
        steps: [],
      }],
    },
  });
  assert.equal(result.supported, false);
  assert.equal(result.diagnostics.filter((item) => item.code === "GGCONV-E517").length, 2);
  assert.match(result.diagnostics.find((item) => item.code === "GGCONV-E517")?.suggestion ?? "", /module/i);
});

test("reports unsupported WRITE additions individually", async () => {
  const result = await convertProgram({ source: "REPORT zwrite.\nWRITE 'x' COLOR 4.\n", filename: "zwrite.prog.abap", mode: "partial" });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E516"));
  assert.match(result.classSource, /TODO GGCONV-E501: unsupported WRITE formatting/);
});

test("lowers classic named WRITE hotspot and color formatting", async () => {
  const result = await convertProgram({
    source: "REPORT zwrite_classic.\nSTART-OF-SELECTION.\nWRITE 15 'Program' HOTSPOT COLOR COL_KEY.\n",
    filename: "zwrite_classic.prog.abap",
    className: "ZCL_WRITE_CLASSIC",
    transactionCode: "ZWRCLASS",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /GGCONV-E516/);
  assert.match(result.classSource, /format = VALUE #\( color = zif_gg_list_processing_types_v1=>color_key hotspot = abap_true \)/);
});

test("lowers classic list color constants through the scaffold interface", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zwrite_color_constant.",
      "DATA lv_color TYPE i.",
      "START-OF-SELECTION.",
      "  lv_color = COND #( WHEN sy-batch = abap_true THEN col_normal ELSE col_negative ).",
      "  FORMAT COLOR = lv_color.",
      "  WRITE / sy-pagno.",
      "  WRITE lv_color.",
    ].join("\n"),
    filename: "zwrite_color_constant.prog.abap",
    className: "ZCL_WRITE_COLOR_CONSTANT",
    transactionCode: "ZWRCOL",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /abap\.builtin\.col_(?:normal|negative)/);
  assert.match(result.classSource, /zif_gg_list_processing_types_v1=>color_normal/);
  assert.match(result.classSource, /zif_gg_list_processing_types_v1=>color_negative/);
  assert.match(result.classSource, /set_format\( VALUE #\( color = lv_color \) \)/i);
  assert.match(result.classSource, /io_session->get_list\( \)->get_context\( \)-page/);
});

test("lowers classic currency WRITE formatting and list paging commands", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zwrite_currency LINE-COUNT 10(2).",
      "DATA gv_price TYPE p DECIMALS 2.",
      "DATA gv_currency TYPE c LENGTH 3.",
      "START-OF-SELECTION.",
      "WRITE / 'Currency'.",
      "WRITE 10 gv_price CURRENCY gv_currency.",
      "AT USER-COMMAND.",
      "  CASE sy-ucomm.",
      "    WHEN 'TOP'. SCROLL LIST TO FIRST PAGE.",
      "    WHEN 'BOTTOM'. SCROLL LIST TO LAST PAGE.",
      "  ENDCASE.",
    ].join("\n"),
    filename: "zwrite_currency.prog.abap",
    className: "ZCL_WRITE_CURRENCY",
    transactionCode: "ZWRCUR",
  });
  assert.equal(result.supported, true);
  assert.deepEqual(result.diagnostics, []);
  assert.match(result.classSource, /write_format = VALUE #\( currency = \|\{ gv_currency \}\| \)/);
  assert.match(result.classSource, /lo_writer->scroll_to_first_page\( \)\./);
  assert.match(result.classSource, /lo_writer->scroll_to_last_page\( \)\./);
});

test("terminates each element of a chained statement", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zchain.",
      "DATA: gv_a TYPE i, gv_b TYPE string, gt_c TYPE STANDARD TABLE OF i WITH EMPTY KEY.",
      "START-OF-SELECTION.",
      "  CLEAR: gv_a, gv_b.",
      "  ADD: 1 TO gv_a, 2 TO gv_a.",
      "  APPEND: 1 TO gt_c, 2 TO gt_c.",
      "  CONDENSE: gv_b, gv_b NO-GAPS.",
    ].join("\n"),
    filename: "zchain.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  for (const statement of ["CLEAR gv_a.", "CLEAR gv_b.", "ADD 1 TO gv_a.", "ADD 2 TO gv_a.", "APPEND 1 TO gt_c.", "APPEND 2 TO gt_c.", "CONDENSE gv_b.", "CONDENSE gv_b NO-GAPS."]) {
    assert.ok(result.classSource.includes(`    ${statement}\n`), `expected ${statement} in the generated class`);
  }
  assert.doesNotMatch(result.classSource, /^\s+(CLEAR|ADD|APPEND|CONDENSE)\b.*,$/m);
});

test("carries statements without a lowering rule over as written", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zno_rule.",
      "DATA gv_start TYPE i.",
      "DATA gv_text TYPE string.",
      "START-OF-SELECTION.",
      "  GET RUN TIME FIELD gv_start.",
      "  CONCATENATE 'a' 'b' INTO gv_text.",
      "  CONDENSE gv_text.",
      "  WHILE gv_start < 10.",
      "    gv_start = gv_start + 1.",
      "  ENDWHILE.",
      "  WAIT UP TO 1 SECONDS.",
    ].join("\n"),
    filename: "zno_rule.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(result.diagnostics.filter((item) => item.severity !== "info"), []);
  for (const statement of ["GET RUN TIME FIELD gv_start.", "CONCATENATE 'a' 'b' INTO gv_text.", "CONDENSE gv_text.", "WHILE gv_start < 10.", "ENDWHILE.", "WAIT UP TO 1 SECONDS."]) {
    assert.ok(result.classSource.includes(statement), `expected ${statement} in the generated class`);
  }
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
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

test("preserves shipped frontend service operations", async () => {
  const result = await convertProgram({
    source: "REPORT zdesktop.\nCALL METHOD cl_gui_frontend_services=>execute.\n",
    filename: "desktop.prog.abap",
    mode: "partial",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E514|TODO GGCONV-E501/);
  assert.match(result.classSource, /cl_gui_frontend_services=>execute/);
});

test("diagnoses dynamic PERFORM instead of emitting a guessed call", async () => {
  const result = await convertProgram({ source: "REPORT zperform.\nPERFORM (lv_form).\n", filename: "zperform.prog.abap", mode: "partial" });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E401"));
  assert.match(result.classSource, /TODO GGCONV-E401/);

});

test("carries object creation and method calls over as written", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zcalls.",
      "DATA go_calc TYPE REF TO zcl_calc.",
      "DATA go_any TYPE REF TO object.",
      "DATA gv_method TYPE string VALUE 'RUN'.",
      "START-OF-SELECTION.",
      "  CREATE OBJECT go_calc.",
      "  CREATE OBJECT go_any TYPE zcl_calc EXPORTING iv_start = 1.",
      "  zcl_calc=>reset( ).",
      "  CALL METHOD zcl_calc=>log EXPORTING iv_text = 'x'.",
      "  go_calc->add( 2 ).",
      "  CALL METHOD go_any->(gv_method).",
      "  CALL METHOD (gv_method).",
      "  cl_gui_frontend_services=>clipboard_export( ).",
    ].join("\n"),
    filename: "zcalls.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /CREATE OBJECT go_calc\./);
  assert.match(result.classSource, /CREATE OBJECT go_any TYPE zcl_calc EXPORTING iv_start = 1\./);
  assert.match(result.classSource, /zcl_calc=>reset\( \)\./);
  assert.match(result.classSource, /CALL METHOD zcl_calc=>log EXPORTING iv_text = 'x'\./);
  assert.match(result.classSource, /go_calc->add\( 2 \)\./);
  assert.match(result.classSource, /CALL METHOD go_any->\(gv_method\)\./);
  assert.match(result.classSource, /CALL METHOD \(gv_method\)\./);
  assert.match(result.classSource, /cl_gui_frontend_services=>clipboard_export\( \)\./);
});

test("still rewrites object creation for report-local classes", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zlocalcreate.",
      "CLASS lcl_app DEFINITION.",
      "  PUBLIC SECTION.",
      "    METHODS run.",
      "ENDCLASS.",
      "CLASS lcl_app IMPLEMENTATION.",
      "  METHOD run.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "DATA go_app TYPE REF TO lcl_app.",
      "START-OF-SELECTION.",
      "  CREATE OBJECT go_app.",
      "  go_app->run( ).",
    ].join("\n"),
    filename: "zlocalcreate.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /CREATE OBJECT go_app EXPORTING io_owner = me io_session = io_session\./);
  assert.match(result.classSource, /go_app->run\( \)\./);
});

test("carries event registrations over as written", async () => {
  const source = [
    "REPORT zglobalhandler.",
    "CLASS lcl_events DEFINITION.",
    "  PUBLIC SECTION.",
    "    METHODS on_changed FOR EVENT changed OF zcl_model IMPORTING sender.",
    "    CLASS-METHODS on_created FOR EVENT created OF zcl_model.",
    "ENDCLASS.",
    "CLASS lcl_events IMPLEMENTATION.",
    "  METHOD on_changed.",
    "  ENDMETHOD.",
    "  METHOD on_created.",
    "  ENDMETHOD.",
    "ENDCLASS.",
    "DATA go_model TYPE REF TO zcl_model.",
    "DATA go_events TYPE REF TO lcl_events.",
    "DATA go_logger TYPE REF TO zcl_logger.",
    "START-OF-SELECTION.",
    "  go_model = NEW #( ).",
    "  go_events = NEW #( ).",
    "  SET HANDLER go_events->on_changed FOR go_model.",
    "  SET HANDLER go_events->on_changed FOR ALL INSTANCES ACTIVATION abap_false.",
    "  SET HANDLER lcl_events=>on_created.",
    "  SET HANDLER go_logger->on_changed go_logger->on_deleted FOR ALL INSTANCES.",
    "  SET HANDLER go_unknown->(lv_name) FOR go_anything.",
  ].join("\n");
  const result = await convertProgram({ source, filename: "zglobalhandler.prog.abap" });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /SET HANDLER go_events->on_changed FOR go_model\./);
  assert.match(result.classSource, /SET HANDLER go_events->on_changed FOR ALL INSTANCES ACTIVATION abap_false\./);
  assert.match(result.classSource, /SET HANDLER zcl_globalhandler_h1=>on_created\./);
  assert.match(result.classSource, /SET HANDLER go_logger->on_changed go_logger->on_deleted FOR ALL INSTANCES\./);
  assert.match(result.classSource, /SET HANDLER go_unknown->\(lv_name\) FOR go_anything\./);
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

test("anchors include diagnostics on the INCLUDE line", async () => {
  const missing = await convertProgram({
    source: "REPORT zinc.\nDATA gv_x TYPE i.\n\nINCLUDE zmissing.\n",
    filename: "zinc.prog.abap",
    resolveInclude: async () => undefined,
  });
  const diagnostic = missing.diagnostics.find((item) => item.code === "GGCONV-E102");
  assert.ok(diagnostic);
  assert.equal(diagnostic.start.line, 4);
});

test("attempts optional INCLUDE ... IF FOUND and tolerates a missing one", async () => {
  const content = "DATA gv_from_include TYPE i.\n";
  const resolvable = await convertProgram({
    source: "REPORT zinc_optional.\nINCLUDE zoptional IF FOUND.\n",
    filename: "zinc_optional.prog.abap",
    resolveInclude: async (name) => name === "zoptional" ? content : undefined,
  });
  assert.ok(!resolvable.diagnostics.some((item) => item.code === "GGCONV-E102"));
  assert.match(resolvable.classSource, /gv_from_include/);

  const absent = await convertProgram({
    source: "REPORT zinc_optional_missing.\nINCLUDE zabsent IF FOUND.\n",
    filename: "zinc_optional_missing.prog.abap",
    resolveInclude: async () => undefined,
  });
  assert.ok(!absent.diagnostics.some((item) => item.code === "GGCONV-E102"));
});

test("keeps dynamic MESSAGE DISPLAY LIKE out of the text and into display_like", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zmsg_display.",
      "DATA gv_text TYPE string.",
      "START-OF-SELECTION.",
      "  MESSAGE gv_text TYPE 'S' DISPLAY LIKE 'E'.",
    ].join("\n"),
    filename: "zmsg_display.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /message_type_success text = \|\{ gv_text \}\| display_like = zif_gg_session_types_v1=>message_type_error/);
  assert.doesNotMatch(result.classSource, /DISPLAY LIKE 'E' \}\|/);

  const literal = await convertProgram({
    source: "REPORT zmsg_display_lit.\nSTART-OF-SELECTION.\nMESSAGE 'looks like an error' TYPE 'S' DISPLAY LIKE 'E'.\n",
    filename: "zmsg_display_lit.prog.abap",
  });
  assert.match(literal.classSource, /type = zif_gg_session_types_v1=>message_type_success text = 'looks like an error' display_like = zif_gg_session_types_v1=>message_type_error/);
});

test("emits valid hoisted local classes for chained declarations and divider comments", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zhoist_bugs.",
      "CLASS lcl_bug DEFINITION.",
      "  PRIVATE SECTION.",
      "************** divider",
      "  DATA: lv_repo_key    TYPE string,",
      "        lv_package     TYPE devclass,",
      "        lv_package_adt TYPE devclass.",
      "  TYPES: BEGIN OF ty_row,",
      "           id TYPE i,",
      "         END OF ty_row.",
      "  DATA: BEGIN OF ls_row,",
      "          id TYPE i,",
      "        END OF ls_row.",
      "  METHODS run.",
      "ENDCLASS.",
      "CLASS lcl_bug IMPLEMENTATION.",
      "  METHOD run.",
      "    DATA: lv_a TYPE i,",
      "          lv_b TYPE i.",
      "    MESSAGE lv_a TYPE 'S' DISPLAY LIKE 'E'.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "  WRITE 'x'.",
    ].join("\n"),
    filename: "zhoist_bugs.prog.abap",
    className: "ZCL_HOIST_BUGS",
    transactionCode: "ZHOISTBUG",
    mode: "partial",
  });
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E202"));
  const helper = result.helperSources[0].source;
  assert.match(helper, /DATA lv_repo_key TYPE string\./);
  assert.match(helper, /DATA lv_package TYPE devclass\./);
  assert.match(helper, /DATA lv_package_adt TYPE devclass\./);
  assert.doesNotMatch(helper, /DATA lv_package TYPE devclass,/);
  assert.match(helper, /^[*]+ divider$/m);
  assert.match(helper, /TYPES: BEGIN OF ty_row, id TYPE i, END OF ty_row\./);
  assert.match(helper, /DATA: BEGIN OF ls_row, id TYPE i, END OF ls_row\./);
  assert.match(helper, /DATA lv_a TYPE i\./);
  assert.match(helper, /DATA lv_b TYPE i\./);
  assert.match(helper, /message_type_success text = \|\{ lv_a \}\| display_like = zif_gg_session_types_v1=>message_type_error/);
});

test("emits valid hoisted structures for non-chained BEGIN OF declarations", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zhoist_classic.",
      "CLASS lcl_bug DEFINITION.",
      "  PRIVATE SECTION.",
      "  DATA BEGIN OF gs_old.",
      "  DATA fld1 TYPE i.",
      "  DATA fld2 TYPE string.",
      "  DATA END OF gs_old.",
      "  TYPES BEGIN OF ty_old.",
      "  TYPES c1 TYPE i.",
      "  TYPES END OF ty_old.",
      "  METHODS run.",
      "ENDCLASS.",
      "CLASS lcl_bug IMPLEMENTATION.",
      "  METHOD run.",
      "    gs_old-fld1 = 1.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "  WRITE 'x'.",
    ].join("\n"),
    filename: "zhoist_classic.prog.abap",
    className: "ZCL_HOIST_CLASSIC",
    transactionCode: "ZHOISTCL",
    mode: "partial",
  });
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E202"));
  const helper = result.helperSources[0].source;
  assert.match(helper, /DATA: BEGIN OF gs_old, fld1 TYPE i, fld2 TYPE string, END OF gs_old\./);
  assert.match(helper, /TYPES: BEGIN OF ty_old, c1 TYPE i, END OF ty_old\./);
});

test("comments out the whole block when a block opener cannot be lowered, and keeps blocks without a rule", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdroploop.",
      "CLASS lcl_bug DEFINITION.",
      "  PUBLIC SECTION.",
      "    METHODS run.",
      "ENDCLASS.",
      "CLASS lcl_bug IMPLEMENTATION.",
      "  METHOD run.",
      "    DATA lt_packages TYPE STANDARD TABLE OF string WITH DEFAULT KEY.",
      "    DATA lv_value TYPE string.",
      "    LOOP AT lt_packages.",
      "      IF lt_packages IS NOT INITIAL.",
      "        lv_value = lt_packages.",
      "      ENDIF.",
      "    ENDLOOP.",
      "    WHILE lv_value IS INITIAL.",
      "      lv_value = 'x'.",
      "    ENDWHILE.",
      "    CLEAR lv_value.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "  WRITE 'x'.",
    ].join("\n"),
    filename: "zdroploop.prog.abap",
    className: "ZCL_DROPLOOP",
    transactionCode: "ZDROPLOOP",
    mode: "partial",
  });
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E202"));
  const helper = result.helperSources[0].source;
  assert.match(helper, /TODO GGCONV-E501: unsupported statement omitted: LOOP AT lt_packages/);
  for (const omitted of ["IF lt_packages IS NOT INITIAL.", "lv_value = lt_packages.", "ENDIF.", "ENDLOOP."]) {
    assert.ok(helper.includes(`* ${omitted}`), `expected commented-out source for ${omitted}`);
  }
  assert.doesNotMatch(helper, /^\s+END(LOOP|IF)\.$/m);
  // WHILE has no lowering rule, so the block is carried over as written.
  assert.match(helper, /^\s+WHILE lv_value IS INITIAL\.\n\s+lv_value = 'x'\.\n\s+ENDWHILE\.$/m);
  // Statements after the omitted blocks still lower normally.
  assert.match(helper, /^\s+CLEAR lv_value\.$/m);
});

test("converts LOOP AT with an ASSIGNING target instead of omitting it", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zassignloop.",
      "CLASS lcl_demo DEFINITION.",
      "  PUBLIC SECTION.",
      "    METHODS run.",
      "ENDCLASS.",
      "CLASS lcl_demo IMPLEMENTATION.",
      "  METHOD run.",
      "    DATA lt_packages TYPE STANDARD TABLE OF string WITH DEFAULT KEY.",
      "    DATA lv_value TYPE string.",
      "    LOOP AT lt_packages ASSIGNING FIELD-SYMBOL(<lv_inline>).",
      "      lv_value = <lv_inline>.",
      "    ENDLOOP.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "  WRITE 'x'.",
    ].join("\n"),
    filename: "zassignloop.prog.abap",
    className: "ZCL_ASSIGNLOOP",
    transactionCode: "ZASSIGNLP",
    mode: "partial",
  });
  assert.ok(!result.diagnostics.some((item) => item.code === "GGCONV-E202"));
  const helper = result.helperSources[0].source;
  assert.match(helper, /^\s+LOOP AT lt_packages ASSIGNING FIELD-SYMBOL\(<lv_inline>\)\.$/m);
  assert.match(helper, /^\s+lv_value = <lv_inline>\.$/m);
  assert.match(helper, /^\s+ENDLOOP\.$/m);
  assert.doesNotMatch(helper, /TODO GGCONV-E501/);

  // The declared-field-symbol form was rejected by the same regex.
  const declared = await convertProgram({
    source: [
      "REPORT zassignloop2.",
      "DATA gt_values TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
      "FIELD-SYMBOLS <lv_value> TYPE i.",
      "START-OF-SELECTION.",
      "LOOP AT gt_values ASSIGNING <lv_value>.",
      "  WRITE / <lv_value>.",
      "ENDLOOP.",
    ].join("\n"),
    filename: "zassignloop2.prog.abap",
    mode: "partial",
  });
  assert.ok(!declared.diagnostics.some((item) => item.code === "GGCONV-E516" && item.message.includes("implicit-header-table LOOP")));
  assert.match(declared.classSource, /^\s+LOOP AT gt_values ASSIGNING <lv_value>\.$/m);
});

test("preserves method-safe LOOP AT over a statically named component table", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zcomponentloop.",
      "CLASS lcl_demo DEFINITION.",
      "  PUBLIC SECTION.",
      "    METHODS run IMPORTING er_data_changed TYPE REF TO cl_alv_changed_data_protocol.",
      "ENDCLASS.",
      "CLASS lcl_demo IMPLEMENTATION.",
      "  METHOD run.",
      "    LOOP AT er_data_changed->mt_mod_cells INTO DATA(ls_cell).",
      "      CONTINUE.",
      "    ENDLOOP.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "  WRITE 'x'.",
    ].join("\n"),
    filename: "zcomponentloop.prog.abap",
    className: "ZCL_COMPONENTLOOP",
    mode: "partial",
  });
  assert.equal(result.supported, true);
  assert.ok(!result.diagnostics.some((item) => item.message.includes("implicit-header-table LOOP")));
  const helper = result.helperSources.find((item) => item.className === "ZCL_COMPONENTLOOP_H1")?.source ?? "";
  assert.match(helper, /LOOP AT er_data_changed->mt_mod_cells INTO DATA\(ls_cell\)\./);
  assert.doesNotMatch(helper, /TODO GGCONV-E501: unsupported statement omitted: LOOP AT er_data_changed/);
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
    transactionCode: "ZCOMPLOCAL",
    mode: "partial",
  });
  assert.equal(localClass.supported, true);
  assert.equal(localClass.helperSources.length, 1);
  assert.match(localClass.classSource, /FRIENDS zcl_composite_local_clas_h1/);
  assert.match(localClass.helperSources[0].source, /CLASS zcl_composite_local_clas_h1 DEFINITION PUBLIC/);

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

test("partial skeleton strategy keeps runnable content for optional gaps", async () => {
  const result = await convertProgram({
    source: "REPORT zpartial_content.\nCALL FUNCTION 'UNKNOWN_OPTIONAL'.\nWRITE 'entry'.\n",
    filename: "zpartial_content.prog.abap",
    mode: "partial",
    partialStrategy: "skeleton",
  });
  assert.equal(result.supported, false);
  assert.match(result.classSource, /METHOD zif_gg_report_v1~start_of_selection\./);
  assert.match(result.classSource, /Application content is available/);
  assert.doesNotMatch(result.classSource, /Partial conversion preview/);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E513"));
});

test("loads report-owned dynpro XML and every matching screen flow file", async () => {
  const metadataFilename = path.join(repositoryRoot, "converter", "test", "fixtures", "dynpro_metadata.prog.xml");
  const metadata = await loadDynproMetadata({
    filename: metadataFilename.replace(/\.prog\.xml$/i, ".prog.abap"),
  });
  assert.equal(metadata.programName, "ZDYNPRO_METADATA");
  assert.deepEqual(metadata.screens.map((screen) => screen.number), ["0100", "0200"]);
  assert.deepEqual(metadata.screens[0].geometry, { width: 80, height: 12, columns: 80, lines: 12 });
  assert.equal(metadata.screens[0].containers[0].kind, "subscreen");
  assert.equal(metadata.screens[0].containers[0].resizable.horizontal, true);
  assert.equal(metadata.screens[0].elements[1].text, "Export XML");
  assert.equal(metadata.screens[0].elements[2].kind, "input-output");
  assert.equal(metadata.screens[0].elements[2].required, true);
  assert.equal(metadata.screens[0].elements[3].ucomm, "APPLY");
  assert.equal(metadata.screens[0].elements[4].kind, "frame");
  assert.equal(metadata.screens[0].elements[4].text, "Input elements");
  assert.equal(metadata.screens[1].modal, true);
  assert.equal(metadata.screens[1].nextScreen, "0000");
  assert.deepEqual(metadata.flowLogic[0].pbo.map((item) => item.name), ["STATUS_0100"]);
  assert.equal(metadata.flowLogic[0].pai[0].atExitCommand, true);
  assert.equal(metadata.flowLogic[0].pai[1].field, "GV_INPUT");
  assert.equal(metadata.flowLogic[0].pov.field, "GV_INPUT");
  assert.equal(metadata.flowLogic[1].poh.modules[0].name, "F1_INPUT");
  assert.equal(metadata.guiStatuses.MAIN.activeUcomm[0], "APPLY");
  assert.equal(metadata.titlebars.TITLE_0100.text, "Metadata sample");
  assert.equal(metadata.screens[0].titlebar.text, "Metadata sample");
  assert.equal(metadata.textPool.GV_INPUT, "Input value");
  assert.equal(metadata.textPool.UNDERSCORE, "File_name");
  assert.equal(metadata.files.screens.length, 2);

  metadata.screens[0].elements[2].visibleLength = 8;
  metadata.screens[0].elements[2].position.visibleWidth = 8;

  const converted = await convertProgram({
    source: "PROGRAM zdynpro_metadata.\nMODULE user_command_0100 INPUT.\nENDMODULE.\n",
    filename: metadataFilename.replace(/\.prog\.xml$/i, ".prog.abap"),
  });
  assert.equal(converted.reportIR.dynproMetadata.screens.length, 2);
  assert.equal(converted.reportIR.dynproMetadata.flowLogic[0].pai[0].name, "EXIT_0100");

  const report = await convertProgram({
    source: "REPORT zscreen_provider.\nDATA gv_value TYPE i.\nMODULE user_command INPUT.\ngv_value = 1.\nENDMODULE.\nSTART-OF-SELECTION.\nWRITE 'ok'.\n",
    filename: "zscreen_provider.prog.abap",
    screenMetadata: metadata,
  });
  assert.equal(report.supported, true);
  assert.ok(report.reportIR.interfaces.includes("zif_gg_report_v1"));
  assert.ok(report.reportIR.interfaces.includes("zif_gg_screen_provider_v1"));
  assert.doesNotMatch(report.classSource, /INTERFACES zif_gg_dynpro_v1/);
  assert.match(report.classSource, /METHOD zif_gg_screen_provider_v1~build_screens\./);
  assert.match(report.classSource, /METHOD zif_gg_screen_provider_v1~process_input_module\.[\s\S]*WHEN 'USER_COMMAND'\.[\s\S]*gv_value = 1\./);
  assert.match(report.classSource, /name = 'GV_INPUT' position = VALUE #\( row = 36 column = 115 width = 80 height = 26 \)/);
  assert.equal(report.diagnostics.some((item) => item.code === "GGCONV-E501" && item.construct.includes("MODULE")), false);
  assert.equal(report.manifest.metadataInputs.screenProvider, true);
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
  assert.ok(unsafe.diagnostics.some((item) => item.code === "GGCONV-E515"));

  const dereferenced = await convertProgram({
    source: [
      "REPORT zfield_deref.",
      "DATA lr_value TYPE REF TO data.",
      "START-OF-SELECTION.",
      "FIELD-SYMBOLS <value> TYPE string.",
      "CREATE DATA lr_value TYPE string.",
      "ASSIGN lr_value->* TO <value>.",
      "<value> = 'ok'.",
      "WRITE <value>.",
    ].join("\n"),
    filename: "zfield_deref.prog.abap",
  });
  assert.equal(dereferenced.supported, true);
  assert.deepEqual(dereferenced.reportIR.safeFieldSymbols, ["VALUE"]);
  assert.match(dereferenced.classSource, /ASSIGN lr_value->\* TO <value>/);
  assert.doesNotMatch(dereferenced.classSource, /TODO GGCONV/);
});

test("renders an honest boundary for an unsupported dynamic ALV table", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdynamic_grid.",
      "DATA go_grid TYPE REF TO cl_gui_alv_grid.",
      "DATA gv_status TYPE string.",
      "DATA gv_detail TYPE string.",
      "FIELD-SYMBOLS <gt_output> TYPE STANDARD TABLE.",
      "FORM display.",
      "  CREATE OBJECT go_grid.",
      "  go_grid->set_table_for_first_display( CHANGING it_outtab = <gt_output> ).",
      "ENDFORM.",
      "FORM append.",
      "  APPEND INITIAL LINE TO <gt_output>.",
      "  gv_status = 'A row was appended'.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zdynamic_grid.prog.abap",
    mode: "partial",
  });

  assert.match(result.classSource, /go_grid->show_capability_boundary/);
  assert.match(result.classSource, /Dynamic ALV output unavailable/);
  assert.match(result.classSource, /browser converter cannot safely reproduce/);
  assert.match(result.classSource, /Dynamic ALV action not applied: generic field-symbol table operations are unsupported/);
  assert.match(result.classSource, /No table rows or cell styles were changed/);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E515"));
});

test("keeps HTML tags literal inside ABAP string templates", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zhtml_template.",
      "DATA gv_frontend TYPE string.",
      "FORM build.",
      "  APPEND |<p><strong>Detected:</strong> { gv_frontend }</p>| TO ct_html.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zhtml_template.prog.abap",
    mode: "partial",
  });
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E515/);
  assert.match(result.classSource, /<p><strong>Detected:<\/strong>/);
});

test("lowers dynamic SET CURSOR field and line operands", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zcursor.",
      "DATA gv_cursor_field TYPE c LENGTH 40 VALUE 'GS_ROW-NAME'.",
      "DATA gv_cursor_line TYPE i VALUE 1.",
      "START-OF-SELECTION.",
      "  SET CURSOR FIELD gv_cursor_field LINE gv_cursor_line.",
    ].join("\n"),
    filename: "zcursor.prog.abap",
    mode: "partial",
  });
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E516: dynamic SET CURSOR/);
  assert.match(result.classSource, /set_cursor\( VALUE #\( field = CONV string\( gv_cursor_field \) row = CONV i\( gv_cursor_line \) \) \)/);
});

test("lowers the finite dynamic ALV field-catalog pattern to a typed table", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zdynamic_typed_grid.",
      "DATA gt_fieldcat TYPE lvc_t_fcat.",
      "DATA gr_table TYPE REF TO data.",
      "DATA gv_style_field TYPE lvc_fname.",
      "FIELD-SYMBOLS <gt_output> TYPE STANDARD TABLE.",
      "FORM display.",
      "  gt_fieldcat = VALUE #( ( fieldname = 'ID' inttype = 'C' intlen = 8 ) ( fieldname = 'ACTIVE' inttype = 'C' intlen = 1 checkbox = abap_true edit = abap_true ) ).",
      "  cl_alv_table_create=>create_dynamic_table( EXPORTING it_fieldcatalog = gt_fieldcat i_style_table = abap_true IMPORTING ep_table = gr_table e_style_fname = gv_style_field ).",
      "  ASSIGN gr_table->* TO <gt_output>.",
      "  APPEND INITIAL LINE TO <gt_output>.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zdynamic_typed_grid.prog.abap",
    mode: "partial",
  });
  assert.ok(result.reportIR.dynamicAlv);
  assert.deepEqual(result.reportIR.safeFieldSymbols, ["GT_OUTPUT"]);
  assert.match(result.classSource, /TYPES: BEGIN OF ty_dynamic_alv_row/);
  assert.match(result.classSource, /active TYPE c LENGTH 1/);
  assert.match(result.classSource, /DATA gt_output TYPE ty_dynamic_alv_rows/);
  assert.match(result.classSource, /GET REFERENCE OF gt_output INTO gr_table/);
  assert.doesNotMatch(result.classSource, /Dynamic ALV output unavailable|TODO GGCONV/);
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

test("lowers global declaration families into ordered class-pool members", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zglobal_declarations.",
      "DATA gv_first TYPE i VALUE 1.",
      "TYPES: BEGIN OF ty_row,",
      "         id TYPE i,",
      "         text TYPE string,",
      "       END OF ty_row.",
      "TYPES ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.",
      "TYPES ty_range TYPE RANGE OF i.",
      "CONSTANTS gc_value TYPE i VALUE 2.",
      "DATA gs_row TYPE ty_row.",
      "DATA gt_rows TYPE ty_rows.",
      "STATICS gv_second TYPE i VALUE 3.",
      "RANGES r_value FOR gv_first.",
      "FIELD-SYMBOLS <gv_ref> TYPE i.",
      "START-OF-SELECTION.",
      "  ASSIGN gv_first TO <gv_ref>.",
      "  <gv_ref> = gc_value.",
      "  APPEND gs_row TO gt_rows.",
      "  WRITE gv_second.",
    ].join("\n"),
    filename: "global-declarations.prog.abap",
  });
  assert.equal(result.supported, true);
  const privateSection = result.classSource.slice(result.classSource.indexOf("PRIVATE SECTION."), result.classSource.indexOf("ENDCLASS."));
  assert.ok(privateSection.indexOf("TYPES: BEGIN OF ty_row") < privateSection.indexOf("DATA gv_first"));
  assert.ok(privateSection.indexOf("DATA gv_first") < privateSection.indexOf("DATA gv_second"));
  assert.match(privateSection, /TYPES ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY\./);
  assert.match(privateSection, /TYPES ty_range TYPE RANGE OF i\./);
  assert.match(privateSection, /CONSTANTS gc_value TYPE i VALUE 2\./);
  assert.match(privateSection, /DATA r_value TYPE zif_gg_selection_screen_types=>ty_ranges\./);
  assert.doesNotMatch(privateSection, /FIELD-SYMBOLS/);
  assert.match(result.classSource, /METHOD zif_gg_report_v1~start_of_selection\.[\s\S]*FIELD-SYMBOLS <gv_ref> TYPE i\.[\s\S]*ASSIGN gv_first TO <gv_ref>/);
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
  assert.ok(dynamic.diagnostics.some((item) => item.code === "GGCONV-E516"));
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
  assert.ok(implicitLoop.diagnostics.some((item) => item.code === "GGCONV-E516" && item.message.includes("implicit-header-table LOOP")));
  assert.match(implicitLoop.classSource, /TODO GGCONV-E501: unsupported statement omitted: LOOP AT gt_values/i);
  // The dropped opener takes its body and its ENDLOOP with it, otherwise the
  // generated method no longer balances.
  assert.match(implicitLoop.classSource, /^\* WRITE \/ gt_values\.$/m);
  assert.match(implicitLoop.classSource, /^\* ENDLOOP\.$/m);
  assert.doesNotMatch(implicitLoop.classSource, /^\s+ENDLOOP\.$/m);
  assert.ok(!implicitLoop.diagnostics.some((item) => item.code === "GGCONV-E202"));

  const functionCall = await convertProgram({
    source: "REPORT zfunction_call.\nCALL FUNCTION 'Z_UNSUPPORTED'.\n",
    filename: "zfunction_call.prog.abap",
    mode: "partial",
  });
  assert.equal(functionCall.supported, false);
  assert.ok(functionCall.diagnostics.some((item) => item.code === "GGCONV-E513" && item.construct.includes("CALL FUNCTION 'Z_UNSUPPORTED'")));
  assert.match(functionCall.classSource, /TODO GGCONV-E501/);
});

test("lowers the finite gg-gui function-module families through typed adapters", async () => {
  const source = [
    "REPORT zcompatibility.",
    "START-OF-SELECTION.",
    "CALL FUNCTION 'POPUP_TO_CONFIRM' EXPORTING titlebar = 'Confirm' text_question = 'Continue?' IMPORTING answer = lv_answer.",
    "CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' EXPORTING retfield = 'VALUE' TABLES value_tab = lt_values return_tab = lt_return.",
    "CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY' EXPORTING i_grid_title = 'Grid' TABLES t_outtab = gt_rows.",
    "CALL FUNCTION 'SELECT_OPTIONS_RESTRICT' EXPORTING restriction = ls_restriction.",
    "CALL FUNCTION 'RS_VARIANT_CONTENTS' EXPORTING report = sy-repid variant = p_variant TABLES valutab = lt_params.",
    "CALL FUNCTION 'DP_PUBLISH_WWW_URL' EXPORTING objid = 'OBJECT' lifetime = 'T' IMPORTING url = lv_url.",
  ].join("\n");
  const result = await convertProgram({ source, filename: "zcompatibility.prog.abap" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /get_compatibility\( \)->popup_to_confirm/);
  assert.match(result.classSource, /get_compatibility\( \)->f4_table_value_request/);
  assert.match(result.classSource, /get_compatibility\( \)->alv_display/);
  assert.match(result.classSource, /get_compatibility\( \)->select_options_restrict/);
  assert.match(result.classSource, /get_compatibility\( \)->variant_contents/);
  assert.match(result.classSource, /get_compatibility\( \)->publish_url/);
  assert.deepEqual(result.manifest.metadataInputs.compatibilityAdapters, [
    "DP_PUBLISH_WWW_URL",
    "F4IF_INT_TABLE_VALUE_REQUEST",
    "POPUP_TO_CONFIRM",
    "REUSE_ALV_GRID_DISPLAY",
    "RS_VARIANT_CONTENTS",
    "SELECT_OPTIONS_RESTRICT",
  ]);
  assert.equal(Object.keys(COMPATIBILITY_FUNCTION_MODULES).length, 34);
});

test("keeps scaffold-owned control constructors and methods type-aware", async () => {
  const source = [
    "REPORT zcontrol_objects.",
    "DATA go_host TYPE REF TO cl_gui_custom_container.",
    "DATA go_grid TYPE REF TO cl_gui_alv_grid.",
    "START-OF-SELECTION.",
    "CREATE OBJECT go_host EXPORTING container_name = 'ROOT'.",
    "CREATE OBJECT go_grid EXPORTING i_parent = go_host.",
    "CALL METHOD go_grid->refresh_table_display.",
    "FREE go_grid.",
  ].join("\n");
  const result = await convertProgram({ source, filename: "zcontrol_objects.prog.abap" });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E501: unsupported (?:CreateObject|Call|Free)/);
  assert.match(result.classSource, /CREATE OBJECT go_host EXPORTING container_name = 'ROOT'\./);
  assert.match(result.classSource, /CREATE OBJECT go_grid EXPORTING i_parent = go_host\./);
  assert.match(result.classSource, /CALL METHOD go_grid->refresh_table_display\./);
  assert.match(result.classSource, /CLEAR: go_grid\./);
});

test("resolves event-handler control parameters and hoisted local event classes", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zevent_control_types.",
      "DATA go_grid TYPE REF TO cl_gui_alv_grid.",
      "DATA go_events TYPE REF TO lcl_events.",
      "CLASS lcl_events DEFINITION FINAL.",
      "  PUBLIC SECTION.",
      "    METHODS on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid IMPORTING e_object.",
      "ENDCLASS.",
      "CLASS lcl_events IMPLEMENTATION.",
      "  METHOD on_toolbar.",
      "    e_object->add_button( fcode = 'ZTEST' icon = '@01@' text = 'Test' quickinfo = 'Test' ).",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "CREATE OBJECT go_grid.",
      "CREATE OBJECT go_events.",
      "SET HANDLER go_events->on_toolbar FOR go_grid.",
    ].join("\n"),
    filename: "zevent_control_types.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E(?:510|511|512)/);
  assert.match(result.classSource, /CREATE OBJECT go_events EXPORTING io_owner = me io_session = io_session\./);
  assert.match(result.classSource, /SET HANDLER go_events->on_toolbar FOR go_grid\./);
  assert.match(result.helperSources[0].source, /e_object->add_button/);
});

test("resolves event parameters inherited by runtime controls", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zinherited_event_control.",
      "DATA go_tree TYPE REF TO cl_gui_column_tree.",
      "DATA go_events TYPE REF TO lcl_events.",
      "CLASS lcl_events DEFINITION FINAL.",
      "  PUBLIC SECTION.",
      "    METHODS on_node_menu FOR EVENT node_context_menu_request OF cl_gui_column_tree IMPORTING menu.",
      "ENDCLASS.",
      "CLASS lcl_events IMPLEMENTATION.",
      "  METHOD on_node_menu.",
      "    menu->add_function( fcode = 'NODE_INFO' text = 'Node info' ).",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "CREATE OBJECT go_tree.",
      "CREATE OBJECT go_events.",
      "SET HANDLER go_events->on_node_menu FOR go_tree.",
    ].join("\n"),
    filename: "zinherited_event_control.prog.abap",
    transactionCode: "ZINHEVENT",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E511/);
  assert.match(result.helperSources[0].source, /menu->add_function/);
});

test("bridges local static methods through their generated helper owner", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zstatic_bridge.",
      "DATA gv_log TYPE string.",
      "CLASS lcl_log DEFINITION FINAL.",
      "  PUBLIC SECTION.",
      "    CLASS-METHODS add IMPORTING text TYPE string.",
      "ENDCLASS.",
      "CLASS lcl_log IMPLEMENTATION.",
      "  METHOD add.",
      "    gv_log = text.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "lcl_log=>add( 'ok' ).",
    ].join("\n"),
    filename: "zstatic_bridge.prog.abap",
    transactionCode: "ZSTATIC",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E501: local static method/);
  assert.match(result.classSource, /zcl_static_bridge_h1=>add\( io_owner = me io_session = io_session TEXT = 'ok' \)/i);
  assert.match(result.helperSources[0].source, /CLASS-METHODS add IMPORTING text TYPE string io_owner TYPE REF TO zcl_static_bridge io_session TYPE REF TO zif_gg_session_v1/);
});

test("resolves FORM parameters and inline runtime event sources", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zsalv_scope_types.",
      "DATA go_salv TYPE REF TO cl_salv_table.",
      "DATA go_events TYPE REF TO lcl_events.",
      "CLASS lcl_events DEFINITION FINAL.",
      "  PUBLIC SECTION.",
      "    METHODS on_added_function FOR EVENT added_function OF cl_salv_events IMPORTING e_salv_function.",
      "ENDCLASS.",
      "CLASS lcl_events IMPLEMENTATION.",
      "  METHOD on_added_function.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "FORM configure USING io_salv TYPE REF TO cl_salv_table.",
      "  DATA(lo_event_source) = go_salv->get_event( ).",
      "  io_salv->get_sorts( )->add_sort( columnname = 'NAME' sequence = 1 position = 1 ).",
      "  SET HANDLER go_events->on_added_function FOR lo_event_source.",
      "ENDFORM.",
      "START-OF-SELECTION.",
      "  CREATE OBJECT go_salv.",
      "  CREATE OBJECT go_events.",
      "  PERFORM configure USING go_salv.",
    ].join("\n"),
    filename: "zsalv_scope_types.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E(?:511|512)/);
  assert.match(result.classSource, /io_salv->get_sorts\( \)->add_sort/);
  assert.match(result.classSource, /SET HANDLER go_events->on_added_function FOR lo_event_source\./);
});

test("lowers chained FREE statements when a control reference is resolved", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zfree_controls.",
      "DATA go_grid TYPE REF TO cl_gui_alv_grid.",
      "DATA go_other TYPE REF TO cl_gui_toolbar.",
      "DATA gv_value TYPE i.",
      "START-OF-SELECTION.",
      "FREE: go_grid, go_other, gv_value.",
    ].join("\n"),
    filename: "zfree_controls.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /CLEAR: go_grid, go_other, gv_value\./);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E516: FREE/);
});

test("lowers ABAP memory statements onto the execution session", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zabap_memory.",
      "DATA gv_count TYPE i.",
      "DATA gv_text TYPE string.",
      "START-OF-SELECTION.",
      "EXPORT gv_count gv_text TO MEMORY ID 'ZGG_MEMORY'.",
      "IMPORT gv_count gv_text FROM MEMORY ID 'ZGG_MEMORY'.",
      "FREE MEMORY ID 'ZGG_MEMORY'.",
    ].join("\n"),
    filename: "zabap_memory.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /io_session->export_memory\( iv_id = 'ZGG_MEMORY' iv_name = 'GV_COUNT' iv_value = gv_count \)\./);
  assert.match(result.classSource, /io_session->import_memory\( EXPORTING iv_id = 'ZGG_MEMORY' iv_name = 'GV_TEXT' CHANGING cv_value = gv_text \)\./);
  assert.match(result.classSource, /io_session->free_memory\( iv_id = 'ZGG_MEMORY' \)\./);
});

test("keeps type-pool declarations as written", async () => {
  const result = await convertProgram({
    source: [
      "REPORT ztype_pools.",
      "TYPE-POOLS: sdydo, cndd.",
      "TYPES ty_flavors TYPE cndd_flavors.",
      "DATA gv_text TYPE sdydo_text_element.",
      "START-OF-SELECTION.",
      "gv_text = 'ok'.",
    ].join("\n"),
    filename: "ztype_pools.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /TYPES ty_flavors TYPE cndd_flavors\./);
});

test("preserves the small static statement tail with explicit rules", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zstatement_tail.",
      "DATA gv_value TYPE i.",
      "DATA lr_value TYPE REF TO data.",
      "FIELD-SYMBOLS <fs> TYPE i.",
      "START-OF-SELECTION.",
      "CREATE DATA lr_value TYPE i.",
      "GET REFERENCE OF gv_value INTO lr_value.",
      "SORT gt_values BY value.",
      "ASSIGN gv_value TO <fs>.",
      "UNASSIGN <fs>.",
      "CONTINUE.",
      "EXIT.",
    ].join("\n"),
    filename: "zstatement_tail.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.doesNotMatch(result.classSource, /TODO GGCONV-E(?:501|515|516)/);
  assert.match(result.classSource, /CREATE DATA lr_value TYPE i\./);
  assert.match(result.classSource, /GET REFERENCE OF gv_value INTO lr_value\./);
});

test("covers PLAN9 lowering and adapter rules with a minimal extracted fixture", async () => {
  const source = await compositeFixture("plan9_minimal_constructs.prog.abap");
  const result = await convertProgram({ source, filename: "plan9_minimal_constructs.prog.abap", transactionCode: "ZPLAN9MIN" });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /TYPES: BEGIN OF ty_row/);
  assert.match(result.classSource, /DATA r_value TYPE zif_gg_selection_screen_types=>ty_ranges/);
  assert.match(result.classSource, /FIELD-SYMBOLS <lv_value> TYPE i/);
  assert.match(result.classSource, /get_compatibility\( \)->popup_to_confirm/);
  assert.match(result.classSource, /get_compatibility\( \)->publish_url/);
  assert.deepEqual(result.manifest.metadataInputs.compatibilityAdapters, Object.keys(COMPATIBILITY_FUNCTION_MODULES).sort());
});

test("classifies former E501 gaps by actionable operation family", async () => {
  const cases = [
    ["CALL FUNCTION 'Z_CUSTOM'.", ACTIONABLE_DIAGNOSTIC_CODES.functionModuleAdapter],
    ["CREATE DATA lr_value TYPE (lv_type).", ACTIONABLE_DIAGNOSTIC_CODES.dynamicType],
  ];
  for (const [statement, code] of cases) {
    const result = await convertProgram({
      source: `REPORT zdiagnostic_family.\n${statement}`,
      filename: "zdiagnostic_family.prog.abap",
      mode: "partial",
    });
    assert.ok(result.diagnostics.some((item) => item.code === code && item.category), `${statement} was not classified as ${code}`);
  }
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

  const unsupplied = await convertProgram({ source: "REPORT zddic.\nTABLES zsflight.\n", filename: "zddic.prog.abap" });
  assert.equal(unsupplied.supported, true, JSON.stringify(unsupplied.diagnostics));
  assert.match(unsupplied.classSource, /DATA zsflight TYPE zsflight\./);
});

test("assumes referenced types exist and emits them as written", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zassumed_types.",
      "TABLES: sflight.",
      "TYPES ty_nodes TYPE treev_ntab.",
      "TYPES ty_keys TYPE STANDARD TABLE OF salv_de_node_key WITH EMPTY KEY.",
      "TYPES ty_products TYPE zcl_gg_gui_demo_data=>ty_products.",
      "TYPES ty_unknown TYPE zsome_type_nobody_supplied.",
      "START-OF-SELECTION.",
      "sflight-carrid = 'LH'.",
    ].join("\n"),
    filename: "zassumed_types.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(result.diagnostics.filter((item) => item.severity !== "info"), []);
  assert.match(result.classSource, /DATA sflight TYPE sflight\./);
  assert.match(result.classSource, /TYPES ty_nodes TYPE treev_ntab\./);
  assert.match(result.classSource, /TYPES ty_keys TYPE STANDARD TABLE OF salv_de_node_key WITH EMPTY KEY\./);
  assert.match(result.classSource, /TYPES ty_products TYPE zcl_gg_gui_demo_data=>ty_products\./);
  assert.match(result.classSource, /TYPES ty_unknown TYPE zsome_type_nobody_supplied\./);
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
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E513"));
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

test("hoists local classes into collision-free helper class sources", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zlocal.",
      "DATA go_events TYPE REF TO lcl_events.",
      "CLASS lcl_events DEFINITION FINAL INHERITING FROM cl_super.",
      "  PUBLIC SECTION.",
      "    DATA mv_public TYPE i READ-ONLY.",
      "    METHODS on_event FOR EVENT changed OF cl_gui_alv_grid IMPORTING sender.",
      "  PRIVATE SECTION.",
      "    DATA mv_private TYPE i.",
      "ENDCLASS.",
      "CLASS lcl_events IMPLEMENTATION.",
      "  METHOD on_event.",
      "    mv_private = 1.",
      "  ENDMETHOD.",
      "ENDCLASS.",
    ].join("\n"),
    filename: "zlocal.prog.abap",
  });
  assert.equal(result.supported, true);
  assert.equal(result.diagnostics.some((item) => item.code === "GGCONV-E305"), false);
  assert.equal(result.reportIR.localClasses.length, 1);
  assert.equal(result.reportIR.localClasses[0].generatedName, "ZCL_LOCAL_H1");
  assert.match(result.classSource, /DATA go_events TYPE REF TO zcl_local_h1\./);
  assert.match(result.classSource, /CLASS zcl_local DEFINITION PUBLIC FINAL CREATE PUBLIC FRIENDS zcl_local_h1\./);
  assert.equal(result.helperSources.length, 1);
  assert.match(result.helperSources[0].source, /CLASS zcl_local_h1 DEFINITION PUBLIC FINAL INHERITING FROM cl_super CREATE PUBLIC\./);
  assert.match(result.helperSources[0].source, /METHODS on_event FOR EVENT changed OF cl_gui_alv_grid IMPORTING sender\./);
  assert.match(result.helperSources[0].source, /PRIVATE SECTION\.[\s\S]*DATA mv_private TYPE i/);
  assert.match(result.helperSources[0].source, /METHOD on_event\.[\s\S]*mv_private = 1\./);

  const collision = await convertProgram({
    source: result.reportIR.source.source,
    filename: "zlocal.prog.abap",
    className: "ZCL_LOCAL",
    transactionCode: "ZLOCAL",
    existingClassNames: ["ZCL_LOCAL_H1"],
  });
  assert.equal(collision.reportIR.localClasses[0].generatedName, "ZCL_LOCAL_H1_1");
  assert.match(collision.classSource, /FRIENDS zcl_local_h1_1\./);
});
