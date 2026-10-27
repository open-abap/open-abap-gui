import assert from "node:assert/strict";
import test from "node:test";
import { convertProgram } from "../../build/src/api.js";

// Statements the converter used to read with regular expressions over their
// text, which matched inside literals and comments or missed a form of the
// syntax. abaplint's syntax tree tells keywords, names and literals apart.

const convert = (name, lines) => convertProgram({ source: lines.join("\n"), filename: `${name}.prog.abap` });

// A generated method's body, from METHOD to ENDMETHOD.
function method(source, name) {
  const start = source.indexOf(`METHOD ${name}.`);
  return start < 0 ? "" : source.slice(start, source.indexOf("ENDMETHOD.", start));
}

// Generated source breaks calls over several lines; a check reads it on one.
const flat = (source) => source.replace(/\s+/g, " ");

test("a comment that reads like an event header starts no event", async () => {
  const result = await convert("zcomment_event", [
    "REPORT zcomment_event.",
    "SELECT-OPTIONS s_val FOR sy-datum.",
    "DATA gv_count TYPE i.",
    "* AT SELECTION-SCREEN ON END OF s_val.",
    "gv_count = 1.",
    "START-OF-SELECTION.",
    "  WRITE gv_count.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.doesNotMatch(method(result.classSource, "zif_gg_report_v1~at_selection_screen_on_end_of"), /gv_count/);
  assert.match(method(result.classSource, "zif_gg_report_v1~start_of_selection"), /gv_count = 1\./);
});

test("a selection screen TITLE TEXT-nnn declares no member", async () => {
  const result = await convert("ztitle_text", [
    "REPORT ztitle_text.",
    "SELECTION-SCREEN BEGIN OF SCREEN 200 TITLE TEXT-t01.",
    "PARAMETERS p_a TYPE i.",
    "SELECTION-SCREEN END OF SCREEN 200.",
    "START-OF-SELECTION.",
    "  CALL SELECTION-SCREEN 200.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.doesNotMatch(result.classSource, /DATA text\b/i);
});

test("bare SELECTION-SCREEN SKIP and ULINE are layout elements", async () => {
  const result = await convert("zbare_layout", [
    "REPORT zbare_layout.",
    "PARAMETERS p_a TYPE i.",
    "SELECTION-SCREEN SKIP.",
    "SELECTION-SCREEN ULINE.",
    "PARAMETERS p_b TYPE i.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /io_builder->add_skip\( 1 \)\.\s+io_builder->add_uline\( VALUE #\( \) \)\./);
});

test("a popup whose text mentions CALL TRANSACTION is a popup continuation", async () => {
  const result = await convert("zpopup_text", [
    "REPORT zpopup_text.",
    "DATA gv_answer TYPE c LENGTH 1.",
    "START-OF-SELECTION.",
    "  CALL FUNCTION 'POPUP_TO_CONFIRM'",
    "    EXPORTING",
    "      text_question = 'Call transaction SE38?'",
    "    IMPORTING",
    "      answer = gv_answer.",
    "  WRITE gv_answer.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /iv_continuation = 'C_[0-9A-F]+'/);
  assert.doesNotMatch(result.classSource, /AFTER_TCODE/);
});

test("a renamed data object keeps its name as a component after COMPARING and BY", async () => {
  const result = await convert("zcomparing", [
    "REPORT zcomparing.",
    "PARAMETERS p_value TYPE i.",
    "TYPES: BEGIN OF ty_row, p_value TYPE i, END OF ty_row.",
    "DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.",
    "START-OF-SELECTION.",
    "  APPEND VALUE #( p_value = p_value ) TO gt_rows.",
    "  DELETE ADJACENT DUPLICATES FROM gt_rows COMPARING p_value.",
    "  SORT gt_rows BY p_value.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const start = method(result.classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /APPEND VALUE #\( p_value = mv_p_value \) TO gt_rows\./);
  assert.match(start, /COMPARING p_value\./);
  assert.match(start, /SORT gt_rows BY p_value\./);
});

test("WRITE keywords inside a literal are text", async () => {
  const result = await convert("zliteral_write", [
    "REPORT zliteral_write.",
    "START-OF-SELECTION.",
    "  WRITE 'Click the hotspot below'.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /lo_writer->write_field\( VALUE #\( text = 'Click the hotspot below' \) \)\./);
});

test("WRITE AT /pos starts a new line at the position", async () => {
  const result = await convert("zwrite_at", [
    "REPORT zwrite_at.",
    "START-OF-SELECTION.",
    "  WRITE AT /5 'Indented'.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /text = 'Indented' placement = VALUE #\( position = 5 new_line = abap_true \)/);
});

test("AUTHORITY-CHECK checks every ID with a FIELD", async () => {
  const result = await convert("zauthority", [
    "REPORT zauthority.",
    "DATA gv_group TYPE c LENGTH 10.",
    "START-OF-SELECTION.",
    "  AUTHORITY-CHECK OBJECT 'Z_OBJ'",
    "    ID 'ACTVT' FIELD '03'",
    "    ID 'ZGROUP' FIELD gv_group",
    "    ID 'ZOTHER' DUMMY.",
    "  WRITE sy-subrc.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const check = (id, value) => `io_session->get_compatibility( )->authority_check( iv_object = 'Z_OBJ' iv_id = '${id}' iv_value = CONV string( ${value} ) ) = abap_true`;
  assert.ok(flat(result.classSource).includes(`sy-subrc = COND #( WHEN ${check("ACTVT", "'03'")} AND ${check("ZGROUP", "gv_group")} THEN 0 ELSE 4 ).`), result.classSource);
  assert.doesNotMatch(result.classSource, /ZOTHER/);
});

test("a local class method typed with a program type names it through the owner class", async () => {
  const result = await convert("zhelper_type", [
    "REPORT zhelper_type.",
    "TYPES: BEGIN OF ty_row, value TYPE i, END OF ty_row.",
    "CLASS lcl_app DEFINITION.",
    "  PUBLIC SECTION.",
    "    METHODS run.",
    "ENDCLASS.",
    "CLASS lcl_app IMPLEMENTATION.",
    "  METHOD run.",
    "    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.",
    "    APPEND VALUE #( value = 1 ) TO lt_rows.",
    "  ENDMETHOD.",
    "ENDCLASS.",
    "START-OF-SELECTION.",
    "  NEW lcl_app( )->run( ).",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.helperSources[0].source, /DATA lt_rows TYPE STANDARD TABLE OF zcl_helper_type=>ty_row WITH EMPTY KEY\./);
});
