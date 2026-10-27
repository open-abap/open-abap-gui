import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import {convertProgram, undeclaredFieldSymbols} from "../../build/src/api.js";
import {applyStyleFixes} from "../../build/src/emit/style-fixes.js";
import {repositoryRoot} from "../repository.mjs";

const fixture = (name) => fs.readFile(path.join(repositoryRoot, "converter", "test", "fixtures", name), "utf8");
const methodOf = (source, name) => source.match(new RegExp(`METHOD ${name.replace(/[~]/g, "\\$&")}\\.[\\s\\S]*?ENDMETHOD\\.`))?.[0] ?? "";
// The code lines, without the comments that quote the source.
const code = (source) => source.split("\n").filter((line) => !line.trimStart().startsWith("*")).join("\n");

test("module DATA is stored in the program instance", async () => {
  const result = await convertProgram({source: `PROGRAM zfoo.
MODULE counter INPUT.
  DATA count TYPE i.
  count = count + 1.
ENDMODULE.`, filename: "zfoo.prog.abap", dynproMetadata: {
    initialScreen: "0100", screens: [{number: "0100"}],
    flowLogic: [{screen: "0100", pai: [{name: "COUNTER"}]}],
  }});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const [definition, implementation] = result.classSource.split("CLASS zcl_foo IMPLEMENTATION.");
  assert.match(definition, /DATA mv_ggconv_count TYPE i\./);
  assert.doesNotMatch(implementation, /DATA mv_ggconv_count/);
  assert.match(implementation, /mv_ggconv_count = mv_ggconv_count \+ 1/);
});

test("popup answers resume the tail without repeating preceding statements", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
DATA count TYPE i.
DATA answer TYPE c.
START-OF-SELECTION.
  count = count + 1.
  CALL FUNCTION 'POPUP_TO_CONFIRM' EXPORTING text_question = 'Continue?' IMPORTING answer = answer.
  WRITE answer.`, filename: "zfoo.prog.abap"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /iv_continuation\s*=/);
  const resume = result.classSource.match(/METHOD zif_gg_resumable_v1~resume\.[\s\S]*?ENDMETHOD\./)?.[0];
  assert.match(resume, /popup_to_confirm/);
  assert.match(resume, /format_value\( iv_value = answer \)/);
  assert.doesNotMatch(resume, /count = count \+ 1/);
});

test("style fixes split parameter sections, constructors and concatenations", () => {
  const formatted = applyStyleFixes(`CLASS zcl_foo DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS main.
ENDCLASS.
CLASS zcl_foo IMPLEMENTATION.
  METHOD main.
    CREATE OBJECT obj EXPORTING parameter = 1.
    obj->method( EXPORTING a = 1 CHANGING b = result ).
    rows = VALUE #( ( name = 'One' ) ( name = 'Two' ) ).
    text = |First| && |Second|.
  ENDMETHOD.
ENDCLASS.`, "zcl_foo");
  assert.match(formatted, /CREATE OBJECT obj\n\s+EXPORTING/);
  assert.match(formatted, /EXPORTING\n\s+a = 1\n\s+CHANGING\n\s+b = result/);
  assert.match(formatted, /name = 'One' \)\n\s+\( name = 'Two'/);
  assert.match(formatted, /\|First\|\n\s+&& \|Second\|/);
});

test("FORMAT changes preserve the preceding color and explicit OFF", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
START-OF-SELECTION.
  FORMAT COLOR COL_HEADING.
  FORMAT INTENSIFIED ON.
  FORMAT INTENSIFIED OFF.
  WRITE 'hello'.`, filename: "zfoo.prog.abap"});
  assert.equal(result.supported, true);
  assert.match(result.classSource, /BASE lo_writer->get_format\( \)/);
  assert.match(result.classSource, /intensified = abap_false/);
});

test("READ LINE INDEX identifies a list level, with variable operands", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
DATA row TYPE i VALUE 3.
DATA level TYPE i VALUE 1.
START-OF-SELECTION.
  READ LINE row INDEX level.`, filename: "zfoo.prog.abap"});
  assert.equal(result.supported, true);
  assert.match(result.classSource, /iv_level\s*= level[\s\S]*iv_index\s*= row/);
});

test("WRITE retains field typing, date masks and DECIMALS zero", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
DATA chars TYPE c LENGTH 12 VALUE 'hello'.
DATA date TYPE d VALUE '20260830'.
DATA number TYPE p LENGTH 8 DECIMALS 2 VALUE '1.23'.
START-OF-SELECTION.
  WRITE chars.
  WRITE date DD/MM/YYYY.
  WRITE number DECIMALS 0.`, filename: "zfoo.prog.abap"});
  assert.equal(result.supported, true);
  assert.match(result.classSource, /format_value\( iv_value = chars \)/);
  assert.match(result.classSource, /iv_date_mask\s*= 'DD\/MM\/YYYY'/);
  assert.match(result.classSource, /decimals\s*= 0[\s\S]*decimals_set\s*= abap_true/);
});

test("LIST_FROM_MEMORY resumes the actual program tail", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
DATA list TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
START-OF-SELECTION.
  SUBMIT ztarget AND RETURN EXPORTING LIST TO MEMORY.
  WRITE 'before memory'.
  CALL FUNCTION 'LIST_FROM_MEMORY' TABLES listobject = list.
  WRITE 'after memory'.`, filename: "zfoo.prog.abap"});
  assert.equal(result.supported, true);
  const resume = result.classSource.match(/METHOD zif_gg_resumable_v1~resume\.[\s\S]*?ENDMETHOD\./)?.[0];
  assert.match(resume, /before memory/);
  assert.match(resume, /it_lines\s*= io_session->get_navigation\( \)->get_list_from_memory\( \)/);
  assert.match(resume, /ct_list\s*= list/);
  assert.match(resume, /after memory/);
});

test("non-ASCII literals and templates emit ASCII source", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
START-OF-SELECTION.
  WRITE 'é'.
  WRITE |Héllo { sy-index }|.`, filename: "zfoo.prog.abap"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /cl_abap_codepage=>convert_from/);
  assert.doesNotMatch(result.classSource, /[^\x00-\x7f]/);
});


test("module structures and chained variables are persistent members", async () => {
  const result = await convertProgram({source: `PROGRAM zfoo.
MODULE counter INPUT.
 DATA: BEGIN OF counters, count TYPE i, END OF counters.
 DATA: first TYPE i, second TYPE i.
 counters-count = counters-count + 1.
ENDMODULE.`, filename: "zfoo.prog.abap", dynproMetadata: {
    initialScreen: "0100", screens: [{number: "0100"}],
    flowLogic: [{screen: "0100", pai: [{name: "COUNTER"}]}],
  }});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /BEGIN OF mv_ggconv_counters/);
  assert.match(result.classSource, /mv_ggconv_counters-count = mv_ggconv_counters-count/);
  assert.match(result.classSource, /DATA mv_ggconv_first TYPE i/);
  assert.match(result.classSource, /DATA mv_ggconv_second TYPE i/);
  assert.doesNotMatch(result.classSource, /DATA mv_ggconv_count TYPE/);
});

test("frontend clipboard and file popups capture continuations", async () => {
  for (const call of ["cl_gui_frontend_services=>clipboard_import( IMPORTING data = rows ).",
    "CALL METHOD cl_gui_frontend_services=>clipboard_import IMPORTING data = rows.",
    "cl_gui_frontend_services=>file_open_dialog( CHANGING file_table = files rc = count ).",
    "cl_gui_frontend_services=>file_save_dialog( CHANGING filename = filename path = path fullpath = fullpath )."]) {
    const result = await convertProgram({source: `REPORT zfoo.
DATA rows TYPE string_table.
DATA files TYPE filetable.
DATA count TYPE i.
DATA: filename TYPE string, path TYPE string, fullpath TYPE string.
START-OF-SELECTION.
 count = count + 1.
 ${call}
 WRITE 'after'.`, filename: "zfoo.prog.abap"});
    assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
    const resume = result.classSource.match(/METHOD zif_gg_resumable_v1~resume\.[\s\S]*?ENDMETHOD\./)?.[0];
    assert.match(resume, /cl_gui_frontend_services=>/);
    assert.match(resume, /iv_continuation\s*=/);
    assert.match(resume, /text = 'after'/);
    assert.doesNotMatch(resume, /count = count \+ 1/);
  }
});

test("POH dispatch leaves help presentation to the program", async () => {
  const result = await convertProgram({source: `PROGRAM zfoo.
MODULE help INPUT.
 MESSAGE 'Program help' TYPE 'I'.
ENDMODULE.`, filename: "zfoo.prog.abap", dynproMetadata: {
    initialScreen: "0100", screens: [{number: "0100"}],
    flowLogic: [{screen: "0100", poh: [{name: "HELP", field: "FIELD"}]}],
  }});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.doesNotMatch(result.classSource, /gv_result/i);
  assert.match(result.classSource, /Program help/);
});


test("non-ASCII titlebar text and WITH operands emit ASCII source", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
START-OF-SELECTION.
 SET TITLEBAR 'MAIN' WITH 'Caf\u00e9'.`, filename: "zfoo.prog.abap",
 screenMetadata: {screens: [], titlebars: {MAIN: {text: "R\u00e9sum\u00e9 &1"}}}});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.doesNotMatch(result.classSource, /[^\x00-\x7f]/);
  assert.match(result.classSource, /cl_abap_codepage=>convert_from/);
  assert.doesNotMatch(result.classSource, /&1/);
});

test("macro expansions keep component selectors and drop the definition", async () => {
  const result = await convertProgram({source: await fixture("regression_macro_components.prog.abap.txt"),
    filename: "zcv_macro.prog.abap", className: "ZCL_CV_MACRO"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const start = methodOf(result.classSource, "zif_gg_report_v1~start_of_selection");
  // Both expansions, the IF and the WRITE of each.
  assert.equal(start.match(/IF sy-dbcnt > 0\./g)?.length, 2);
  assert.equal(start.match(/format_value\( iv_value = sy-dbcnt \)/g)?.length, 2);
  assert.match(start, /DELETE FROM zsflight WHERE carrid = 'AA'\.[\s\S]*DELETE FROM zsflight WHERE carrid = 'LH'\./);
  assert.doesNotMatch(result.classSource, /sy - dbcnt|&1/);
  // The calls are expanded, so neither they nor the definition are code.
  assert.doesNotMatch(code(result.classSource), /DEFINE|END-OF-DEFINITION|^\s*delete_flights\b/m);
  assert.match(start, /\* Macro expanded by converter: delete_flights 'AA'\./);
  assert.equal(start.match(/set_title/g)?.length, 1);
});

test("helper classes reach the report's constants and types through the owner", async () => {
  const result = await convertProgram({source: await fixture("regression_helper_owner.prog.abap.txt"),
    filename: "zcv_helper_owner.prog.abap", className: "ZCL_CV_HELPER"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const helper = result.helperSources[0].source;
  const command = methodOf(helper, "on_command");
  assert.match(command, /IF iv_ucomm = zcl_cv_helper=>gc_cmd_refresh\./);
  assert.match(command, /mo_owner->gv_mode = zcl_cv_helper=>gc_mode-show\./);
  // The helper's own attribute named like a component of the constant.
  assert.match(command, /^\s*show = abap_true\./m);
  assert.match(helper, /is_params\s+TYPE zcl_cv_helper=>ty_params/);
  assert.match(helper, /DATA ms_params TYPE zcl_cv_helper=>ty_params\./);
  // The constants stay private; the helper is a friend of the owner.
  const [definition] = result.classSource.split("CLASS zcl_cv_helper IMPLEMENTATION.");
  assert.match(definition, /FRIENDS zcl_cv_helper_h1/);
  assert.match(definition.split("PRIVATE SECTION.")[1], /CONSTANTS gc_cmd_refresh TYPE sy-ucomm VALUE 'REFRESH'\./);
});

test("helper factories pass the owner and the session to the constructor", async () => {
  const result = await convertProgram({source: await fixture("regression_helper_owner.prog.abap.txt"),
    filename: "zcv_helper_owner.prog.abap", className: "ZCL_CV_HELPER"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const helper = result.helperSources[0].source;
  assert.match(helper, /DEFINITION PUBLIC CREATE PRIVATE\./);
  assert.match(helper, /METHODS constructor\s+IMPORTING\s+is_params\s+TYPE zcl_cv_helper=>ty_params\s+io_owner\s+TYPE REF TO zcl_cv_helper\s+io_session TYPE REF TO zif_gg_session_v1\./);
  // Static methods get the owner as a parameter, instance methods keep it.
  assert.match(methodOf(helper, "create"), /ro_obj = NEW zcl_cv_helper_h1\( io_owner\s+= io_owner\s+io_session = io_session\s+is_params\s+= is_params \)\./);
  assert.match(methodOf(helper, "create_classic"), /CREATE OBJECT ro_obj\s+EXPORTING io_owner\s+= io_owner\s+io_session = io_session\s+is_params\s+= is_params\./);
  assert.match(methodOf(helper, "clone"), /ro_obj = NEW #\( io_owner\s+= mo_owner\s+io_session = mo_session\s+is_params\s+= ms_params \)\./);
  // The variable DATA( ) declares from the factory holds a reference.
  assert.match(result.classSource, /DATA lo_handler TYPE REF TO zcl_cv_helper_h1\./);
});

test("a FORM's own field symbol hides the global one of the same name", async () => {
  const result = await convertProgram({source: await fixture("regression_field_symbol_scope.prog.abap.txt"),
    filename: "zcv_fs_scope.prog.abap", className: "ZCL_CV_FS_SCOPE"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const copy = methodOf(result.classSource, "form_copy_data");
  assert.equal(copy.match(/FIELD-SYMBOLS <ls_upload>/g)?.length, 1);
  assert.match(copy, /FIELD-SYMBOLS <ls_upload> LIKE LINE OF gt_upload\./);
  // Its binding is not the global one the class keeps.
  assert.doesNotMatch(copy, /mr_ggconv_ls_upload/);
  assert.doesNotMatch(methodOf(result.classSource, "zif_gg_report_v1~start_of_selection"), /mr_ggconv_ls_upload/);
  assert.match(methodOf(result.classSource, "form_pick"), /GET REFERENCE OF <ls_upload> INTO mr_ggconv_ls_upload\./);
  assert.match(methodOf(result.classSource, "form_show"), /ASSIGN mr_ggconv_ls_upload->\* TO <ls_upload>\./);
});

test("the resume method declares the field symbols of the FORM it continues", async () => {
  const result = await convertProgram({source: await fixture("regression_field_symbol_scope.prog.abap.txt"),
    filename: "zcv_fs_scope.prog.abap", className: "ZCL_CV_FS_SCOPE"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const resume = methodOf(result.classSource, "zif_gg_resumable_v1~resume");
  assert.match(resume, /FIELD-SYMBOLS <ls_row> LIKE LINE OF gt_upload\./);
  assert.match(resume, /READ TABLE gt_upload INDEX 1 ASSIGNING <ls_row>\.[\s\S]*<ls_row>-id = <ls_row>-id \+ 1\./);
  assert.deepEqual(undeclaredFieldSymbols(result.classSource), []);
});

test("a FORM field symbol bound before a suspension is not used after it", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
TYPES: BEGIN OF ty_row, id TYPE i, END OF ty_row.
DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
DATA gv_answer TYPE c LENGTH 1.
FORM confirm.
  FIELD-SYMBOLS <ls_row> LIKE LINE OF gt_rows.
  READ TABLE gt_rows INDEX 1 ASSIGNING <ls_row>.
  CALL FUNCTION 'POPUP_TO_CONFIRM' EXPORTING text_question = 'Go?' IMPORTING answer = gv_answer.
  <ls_row>-id = 1.
ENDFORM.
START-OF-SELECTION.
  PERFORM confirm.`, filename: "zfoo.prog.abap", mode: "partial"});
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E515" && /<ls_row> in FORM CONFIRM/.test(item.message)));
  const resume = methodOf(result.classSource, "zif_gg_resumable_v1~resume");
  assert.match(resume, /TODO GGCONV-E515: statement omitted, field symbol <ls_row> has no convertible binding: <ls_row>-id = 1\./);
  assert.doesNotMatch(code(resume), /<ls_row>/);
  assert.deepEqual(undeclaredFieldSymbols(result.classSource), []);
});

test("the post-emit gate checks field symbols per method", () => {
  assert.deepEqual(undeclaredFieldSymbols([
    "CLASS zcl_gap IMPLEMENTATION.",
    "  METHOD declares.",
    "    FIELD-SYMBOLS <ls_row> TYPE i.",
    "    <ls_row> = 1.",
    "  ENDMETHOD.",
    "  METHOD uses.",
    "    <ls_row> = 2.",
    "  ENDMETHOD.",
    "ENDCLASS.",
  ].join("\n")), [["LS_ROW", 7]]);
});

test("modules lowered into one method each declare their own LOOP AT SCREEN field symbol", async () => {
  const result = await convertProgram({source: await fixture("regression_merged_screen_modules.prog.abap.txt"),
    filename: "zcv_screen_modules.prog.abap", className: "ZCL_CV_SCREEN_MODULES", dynproMetadata: {
      initialScreen: "0100", screens: [{number: "0100"}],
      flowLogic: [{screen: "0100",
        pbo: [{name: "SET_FIRST"}, {name: "SET_SECOND"}, {name: "FILL_ROWS"}],
        pai: [{name: "CHECK_FIRST"}, {name: "CHECK_SECOND"}]}],
    }});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const output = methodOf(result.classSource, "output_modules");
  // FILL_ROWS declares <ls_state> itself, so the screen loops take others.
  for (const symbol of ["ls_state", "ls_state_1", "ls_state_2"]) {
    assert.equal(output.match(new RegExp(`FIELD-SYMBOL\\(<${symbol}>\\)`, "g"))?.length, 1, symbol);
  }
  assert.match(output, /LOOP AT gt_rows ASSIGNING FIELD-SYMBOL\(<ls_state>\)\./);
  assert.match(output, /<ls_state_1>-input = abap_false\./);
  // A flag of a renamed field symbol is still a boolean.
  assert.match(output, /<ls_state_2>-intensified = abap_true\./);
  const input = methodOf(result.classSource, "input_modules");
  assert.match(input, /<ls_state>-input = abap_true\./);
  assert.match(input, /<ls_screen>-required = abap_true\./);
});

test("members for promoted locals stay within 30 characters and unique", async () => {
  const input = {source: await fixture("regression_long_promoted_names.prog.abap.txt"),
    filename: "zcv_long_names.prog.abap", className: "ZCL_CV_LONG_NAMES", dynproMetadata: {
      initialScreen: "0100", screens: [{number: "0100"}],
      flowLogic: [{screen: "0100", pai: [{name: "BUILD"}, {name: "ASK"}]}],
    }};
  const result = await convertProgram(input);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const members = [...new Set(result.classSource.match(/\bmv_ggconv_\w+/g))].sort();
  assert.deepEqual(members, [
    "mv_ggconv_lt_fieldcatalog_sh_2",
    "mv_ggconv_lt_fieldcatalog_sh_3",
    // Short enough as it is, so no shortened name may take it.
    "mv_ggconv_lt_fieldcatalog_ship",
    "mv_ggconv_lv_answer_from_the_l",
  ]);
  assert.match(result.classSource, /DATA mv_ggconv_lt_fieldcatalog_sh_2 TYPE STANDARD TABLE OF string WITH DEFAULT KEY\./);
  assert.match(result.classSource, /DATA mv_ggconv_lt_fieldcatalog_sh_3 TYPE STANDARD TABLE OF i WITH DEFAULT KEY\./);
  assert.equal((await convertProgram(input)).classSource, result.classSource);
});
