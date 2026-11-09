import assert from "node:assert/strict";
import test from "node:test";
import {convertProgram} from "../../build/src/api.js";

// GGCONV-REG-045..051: constructs a consumer's macro-heavy program and its
// includes raised, see fixtures/REGRESSIONS.md; examples/zgg_ex_208 to
// zgg_ex_214 are the same constructs as complete programs.

const methodOf = (source, name) => source.match(new RegExp(`METHOD ${name.replace(/[~]/g, "\\$&")}\\.[\\s\\S]*?ENDMETHOD\\.`))?.[0] ?? "";
// The code lines, without the comments that quote the source.
const code = (source) => source.split("\n").filter((line) => !line.trimStart().startsWith("*")).join("\n");
const blocking = (result, ...codes) => result.diagnostics
  .filter((item) => codes.includes(item.code))
  .map((item) => `${item.code} ${item.message}`);
const includes = (sources) => async (name) => sources[name];

test("GGCONV-REG-045: a macro the main program defines expands in its includes", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
DATA gt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DEFINE add_line.
  APPEND &1 TO gt_lines.
END-OF-DEFINITION.
INCLUDE zfoo_f01.
START-OF-SELECTION.
  PERFORM collect.`, filename: "zfoo.prog.abap", resolveInclude: includes({zfoo_f01: `FORM collect.
  add_line \`Start\`.
  add_line \`End\`.
ENDFORM.`})});
  assert.deepEqual(blocking(result, "GGCONV-E201"), []);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(code(methodOf(result.classSource, "form_collect")), /APPEND `Start` TO gt_lines\.\s+APPEND `End` TO gt_lines\./);
});

test("GGCONV-REG-046: an untyped field symbol is TYPE any, and ASSIGN ... CASTING binds", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
INCLUDE zfoo_top.
START-OF-SELECTION.
  PERFORM split.`, filename: "zfoo.prog.abap", resolveInclude: includes({zfoo_top: `TYPES: BEGIN OF ty_code,
         country TYPE c LENGTH 2,
         number  TYPE c LENGTH 4,
       END OF ty_code.
DATA gv_code TYPE c LENGTH 6 VALUE 'DK1234'.
FIELD-SYMBOLS <gv_field>.
FORM split.
  FIELD-SYMBOLS <ls_code> TYPE ty_code.
  ASSIGN gv_code TO <ls_code> CASTING.
  ASSIGN gv_code TO <gv_field>.
  WRITE: / <ls_code>-country, <gv_field>.
ENDFORM.`})});
  assert.deepEqual(blocking(result, "GGCONV-E515"), []);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const split = methodOf(result.classSource, "form_split");
  assert.match(split, /FIELD-SYMBOLS <gv_field> TYPE any\./);
  assert.match(split, /ASSIGN gv_code TO <ls_code> CASTING\./);
});

test("GGCONV-REG-046: CASTING TYPE (name) and the STRUCTURE form are still GGCONV-E515", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
DATA gv_raw TYPE c LENGTH 8.
FIELD-SYMBOLS <gs_struct> STRUCTURE gv_raw DEFAULT gv_raw.
FIELD-SYMBOLS <gv_any> TYPE any.
START-OF-SELECTION.
  ASSIGN gv_raw TO <gv_any> CASTING TYPE ('TY_X').
  WRITE / <gs_struct>.`, filename: "zfoo.prog.abap"});
  assert.deepEqual(result.diagnostics.filter((item) => item.code === "GGCONV-E515").map((item) => item.start.line), [3, 4, 6]);
});

test("GGCONV-REG-047: components of structured constants and a FORM named like data do not collide", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
CONSTANTS: BEGIN OF gc_mode,
             add TYPE c LENGTH 1 VALUE 'A',
           END OF gc_mode.
CONSTANTS: BEGIN OF gc_label,
             add TYPE string VALUE \`Add\`,
           END OF gc_label.
DATA total TYPE i.
START-OF-SELECTION.
  PERFORM total.
  WRITE: / gc_mode-add, gc_label-add, total.
FORM total.
  total = 42.
ENDFORM.`, filename: "zfoo.prog.abap"});
  assert.deepEqual(blocking(result, "GGCONV-E204"), []);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
});

test("GGCONV-REG-047: two FORMs of one name still collide", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
START-OF-SELECTION.
  PERFORM twice.
FORM twice.
ENDFORM.
FORM twice.
ENDFORM.`, filename: "zfoo.prog.abap"});
  assert.equal(blocking(result, "GGCONV-E204").length, 1, JSON.stringify(result.diagnostics));
});

test("GGCONV-REG-048: SCREEN in a FORM performed inside LOOP AT SCREEN is the loop's current row", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
PARAMETERS p_name TYPE c LENGTH 20 MODIF ID nam.
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    PERFORM set_input.
    MODIFY SCREEN.
  ENDLOOP.
FORM set_input.
  IF screen-group1 = 'NAM'.
    screen-input = 0.
  ENDIF.
ENDFORM.`, filename: "zfoo.prog.abap"});
  assert.deepEqual(blocking(result, "GGCONV-E205"), []);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /DATA mr_selection_screen TYPE REF TO zif_gg_selection_screen_types=>ty_state\./);
  assert.match(methodOf(result.classSource, "zif_gg_report_v1~at_selection_screen_output"),
    /LOOP AT ct_states ASSIGNING FIELD-SYMBOL\(<ls_state>\)\.\s+mr_selection_screen = REF #\( <ls_state> \)\./);
  const form = code(methodOf(result.classSource, "form_set_input"));
  assert.match(form, /IF mr_selection_screen IS NOT BOUND\.\s+mr_selection_screen = NEW #\( \)\.\s+ENDIF\./);
  assert.match(form, /IF mr_selection_screen->modif_id = 'NAM'\.\s+mr_selection_screen->input = abap_false\./);
  assert.doesNotMatch(form, /<ls_state>/);
});

const dynpro = ({pbo = [], pai = []}) => ({
  initialScreen: "0100",
  screens: [{number: "0100", elements: [{kind: "input", name: "GV_TEXT", line: 1, column: 1, length: 10, attributes: {group2: "OUT"}}]}],
  flowLogic: [{screen: "0100", pbo: pbo.map((name) => ({name})), pai: pai.map((name) => ({name}))}],
});

test("GGCONV-REG-049: PERFORM temporaries of modules lowered into one method are numbered apart", async () => {
  const result = await convertProgram({source: `PROGRAM zfoo.
DATA gv_text TYPE c LENGTH 10.
MODULE first INPUT.
  PERFORM describe USING 'One'.
ENDMODULE.
MODULE second INPUT.
  PERFORM describe USING 'Two'.
ENDMODULE.
FORM describe USING iv_text TYPE c.
  gv_text = iv_text.
  iv_text = space.
ENDFORM.`, filename: "zfoo.prog.abap", dynproMetadata: dynpro({pai: ["FIRST", "SECOND"]})});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /DATA\(lv_perform_1\) = 'One'\./);
  assert.match(result.classSource, /DATA\(lv_perform_2\) = 'Two'\./);
});

test("GGCONV-REG-050: dynpro SCREEN-GROUP2 is the state's group2", async () => {
  const result = await convertProgram({source: `PROGRAM zfoo.
DATA gv_text TYPE c LENGTH 10.
MODULE status OUTPUT.
  LOOP AT SCREEN.
    PERFORM protect.
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.
FORM protect.
  IF screen-group2 = 'OUT'.
    screen-input = 0.
  ENDIF.
ENDFORM.`, filename: "zfoo.prog.abap", dynproMetadata: dynpro({pbo: ["STATUS"]})});
  assert.deepEqual(blocking(result, "GGCONV-E205"), []);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(code(methodOf(result.classSource, "form_protect")), /IF mr_dynpro_screen->group2 = 'OUT'\.\s+mr_dynpro_screen->input = abap_false\./);
  assert.match(result.classSource, /name = 'GV_TEXT' [^)]*\) group2 = 'OUT'/);
});

test("GGCONV-REG-050: a SCREEN component no screen state has is diagnosed, not copied", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
PARAMETERS p_a TYPE c LENGTH 10.
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    screen-length = 5.
    screen-value_help = 0.
    MODIFY SCREEN.
  ENDLOOP.`, filename: "zfoo.prog.abap", mode: "partial"});
  assert.deepEqual(blocking(result, "GGCONV-E516"), ["GGCONV-E516 SCREEN-LENGTH has no counterpart in the converted screen state"]);
  const output = code(methodOf(result.classSource, "zif_gg_report_v1~at_selection_screen_output"));
  assert.doesNotMatch(output, /screen-length/i);
  assert.match(output, /<ls_state>-value_help = abap_false\./);
});

test("GGCONV-REG-051: a local-class method's own DATA hides the report global, and a TABLES type stays a type", async () => {
  const result = await convertProgram({source: `REPORT zfoo.
TABLES t000.
DATA gt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA lv_count TYPE i.
CLASS lcl_app DEFINITION.
  PUBLIC SECTION.
    METHODS run.
ENDCLASS.
CLASS lcl_app IMPLEMENTATION.
  METHOD run.
    DATA ls_client TYPE t000.
    DATA(lv_count) = lines( gt_rows ).
    READ TABLE gt_rows INTO DATA(lv_row) INDEX 1.
    t000 = ls_client.
    WRITE: / lv_count, lv_row.
  ENDMETHOD.
ENDCLASS.
START-OF-SELECTION.
  NEW lcl_app( )->run( ).`, filename: "zfoo.prog.abap"});
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const run = code(methodOf(result.helperSources[0].source, "run"));
  assert.match(run, /DATA ls_client TYPE t000\./);
  assert.match(run, /DATA\(lv_count\) = lines\( mo_owner->gt_rows \)\./);
  assert.match(run, /mo_owner->t000 = ls_client\./);
  assert.doesNotMatch(run, /DATA\(mo_owner->|TYPE mo_owner->/);
});
