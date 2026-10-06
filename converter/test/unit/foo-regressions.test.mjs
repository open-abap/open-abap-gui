import assert from "node:assert/strict";
import test from "node:test";
import {convertProgram} from "../../src/api.mjs";
import {applyStyleFixes} from "../../src/emit/style-fixes.mjs";

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
