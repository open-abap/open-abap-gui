import assert from "node:assert/strict";
import test from "node:test";
import { convertProgram } from "../../build/src/api.js";

const builderCall = (source, name) => source.match(new RegExp(`io_builder->add_\\w+\\( VALUE #\\( name = '${name}'[^\\n]*`))?.[0] ?? "";

test("keeps the selection screen number in events, FORM calls and compatibility functions", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zscreen_number.",
      "DATA gv_screen TYPE sy-dynnr.",
      "AT SELECTION-SCREEN OUTPUT.",
      "  gv_screen = sy-dynnr.",
      "  PERFORM screen_number.",
      "AT SELECTION-SCREEN.",
      "  IF sy-dynnr = '1000'.",
      "    MESSAGE sy-dynnr TYPE 'S'.",
      "  ENDIF.",
      "  CALL FUNCTION 'RS_SET_SELSCREEN_STATUS' EXPORTING p_status = 'MAIN' p_program = sy-repid p_dynnr = sy-dynnr.",
      "  CALL FUNCTION 'POPUP_TO_INFORM' EXPORTING titel = sy-dynnr txt1 = 'Screen'.",
      "FORM screen_number.",
      "  gv_screen = sy-dynnr.",
      "  IF sy-dynnr = '0100'.",
      "    MESSAGE sy-dynnr TYPE 'S'.",
      "  ENDIF.",
      "  CALL FUNCTION 'RS_SET_SELSCREEN_STATUS' EXPORTING p_status = 'TAB' p_program = sy-repid p_dynnr = sy-dynnr.",
      "  CALL FUNCTION 'POPUP_TO_INFORM' EXPORTING titel = sy-dynnr txt1 = 'Screen'.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zscreen_number.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /gv_screen = iv_screen\./);
  assert.match(result.classSource, /IF iv_screen = '1000'\./);
  assert.match(result.classSource, /ia_text\s*= iv_screen/);
  assert.match(result.classSource, /p_dynnr = iv_screen/);
  assert.match(result.classSource, /title = iv_screen/);
  assert.match(result.classSource, /gv_screen = io_session->get_context\( \)-selection-screen\./);
  assert.match(result.classSource, /IF io_session->get_context\( \)-selection-screen = '0100'\./);
  assert.match(result.classSource, /ia_text\s*= io_session->get_context\( \)-selection-screen/);
  assert.match(result.classSource, /p_dynnr = io_session->get_context\( \)-selection-screen/);
  assert.match(result.classSource, /title = io_session->get_context\( \)-selection-screen/);
  assert.match(result.classSource, /gv_screen TYPE sy-dynnr/);
  assert.doesNotMatch(result.classSource, /gv_screen = ''|IF '' =|iv_screen = ''/);
});

test("applies a radio group's USER-COMMAND to every button of the group", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zradio.",
      "PARAMETERS: p_in  RADIOBUTTON GROUP dir USER-COMMAND dir DEFAULT 'X',",
      "            p_out RADIOBUTTON GROUP dir,",
      "            p_all RADIOBUTTON GROUP dir.",
      "PARAMETERS: p_a RADIOBUTTON GROUP oth DEFAULT 'X',",
      "            p_b RADIOBUTTON GROUP oth.",
    ].join("\n"),
    filename: "zradio.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  for (const name of ["P_IN", "P_OUT", "P_ALL"]) assert.match(builderCall(result.classSource, name), /radio_group = 'DIR'.*ucomm = 'DIR'/);
  // A group without USER-COMMAND raises nothing.
  for (const name of ["P_A", "P_B"]) assert.doesNotMatch(builderCall(result.classSource, name), /ucomm/);
});

test("keeps MODIF ID on select-options, radio buttons and listboxes", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zmodif.",
      "DATA gv_queue TYPE c LENGTH 20.",
      "PARAMETERS: p_in  RADIOBUTTON GROUP dir USER-COMMAND dir DEFAULT 'X' MODIF ID dir,",
      "            p_out RADIOBUTTON GROUP dir MODIF ID dir.",
      "SELECT-OPTIONS s_in FOR gv_queue MODIF ID in.",
      "SELECT-OPTIONS s_out FOR gv_queue MODIF ID out MATCHCODE OBJECT zqueue LOWER CASE.",
      "PARAMETERS p_list TYPE c LENGTH 2 AS LISTBOX VISIBLE LENGTH 10 MODIF ID out.",
      "AT SELECTION-SCREEN OUTPUT.",
      "  LOOP AT SCREEN.",
      "    IF screen-group1 = 'OUT'.",
      "      screen-active = COND #( WHEN p_out = abap_true THEN '1' ELSE '0' ).",
      "    ENDIF.",
      "    IF screen-group1 = 'IN'.",
      "      screen-input = COND #( WHEN p_in = abap_true THEN '1' ELSE '0' ).",
      "    ENDIF.",
      "    MODIFY SCREEN.",
      "  ENDLOOP.",
    ].join("\n"),
    filename: "zmodif.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(builderCall(result.classSource, "S_IN"), /modif_id = 'IN'/);
  const out = builderCall(result.classSource, "S_OUT");
  assert.match(out, /modif_id = 'OUT'/);
  assert.match(out, /search_help = 'ZQUEUE'/);
  assert.match(out, /value_help = abap_true/);
  assert.match(out, /lower_case = abap_true/);
  assert.match(builderCall(result.classSource, "P_IN"), /modif_id = 'DIR'/);
  assert.match(builderCall(result.classSource, "P_LIST"), /modif_id = 'OUT'/);
  // The states the output event changes are the ones the MODIF IDs name, and
  // SCREEN's '1'/'0' flags become the state's abap_bool flags.
  assert.match(result.classSource, /<ls_state>-modif_id = 'OUT'/);
  assert.match(result.classSource, /<ls_state>-modif_id = 'IN'/);
  assert.match(result.classSource, /<ls_state>-visible = xsdbool\( mv_p_out = abap_true \)\./);
  assert.match(result.classSource, /<ls_state>-input = xsdbool\( mv_p_in = abap_true \)\./);
});

test("reads the obsolete PARAMETER keyword and a chained parameter", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zparameter.",
      "TYPES ty TYPE i.",
      "PARAMETER :p_file TYPE ty.",
      "SELECT-OPTIONS: s_file FOR sy-datum.",
    ].join("\n"),
    filename: "zparameter.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(builderCall(result.classSource, "P_FILE"), /data_type = VALUE #\( typ = 'I' \)/);
  assert.notEqual(builderCall(result.classSource, "S_FILE"), "");
});

test("gives a select-option a header line, also inside a FORM", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zheader.",
      "SELECT-OPTIONS s_date FOR sy-datum.",
      "FORM run.",
      "  s_date-sign = 'I'.",
      "  LOOP AT s_date.",
      "    WRITE / s_date-low.",
      "  ENDLOOP.",
      "  IF sy-datum IN s_date.",
      "    CLEAR s_date[].",
      "  ENDIF.",
      "ENDFORM.",
      "START-OF-SELECTION.",
      "  PERFORM run.",
    ].join("\n"),
    filename: "zheader.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /DATA s_date_header LIKE LINE OF mv_s_date\./);
  assert.match(result.classSource, /s_date_header-sign = 'I'\./);
  assert.match(result.classSource, /LOOP AT mv_s_date INTO s_date_header\./);
  assert.match(result.classSource, /iv_value = s_date_header-low/);
  assert.match(result.classSource, /IF sy-datum IN mv_s_date\./);
  assert.match(result.classSource, /CLEAR mv_s_date\./);
});

test("reads a SELECT without INTO into the TABLES work area", async () => {
  const result = await convertProgram({
    source: [
      "REPORT ztables.",
      "TABLES t100.",
      "SELECT-OPTIONS s_arbgb FOR t100-arbgb.",
      "FORM run.",
      "  SELECT SINGLE * FROM t100 WHERE arbgb IN s_arbgb.",
      "ENDFORM.",
      "START-OF-SELECTION.",
      "  PERFORM run.",
      "  SELECT * FROM t100 UP TO 2 ROWS.",
      "  ENDSELECT.",
    ].join("\n"),
    filename: "ztables.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /SELECT SINGLE \* FROM t100 INTO t100 WHERE arbgb IN mv_s_arbgb\./);
  assert.match(result.classSource, /SELECT \* FROM t100 INTO t100 UP TO 2 ROWS\./);
});

test("passes an escaped select-option to Open SQL as its table", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zescaped.",
      "TABLES t100.",
      "SELECT-OPTIONS s_arbgb FOR t100-arbgb.",
      "FORM run.",
      "  DATA bar TYPE t100.",
      "  SELECT SINGLE * FROM t100 INTO CORRESPONDING FIELDS OF @bar WHERE arbgb IN @s_arbgb.",
      "ENDFORM.",
      "START-OF-SELECTION.",
      "  PERFORM run.",
    ].join("\n"),
    filename: "zescaped.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /WHERE arbgb IN @mv_s_arbgb\./);
  assert.doesNotMatch(result.classSource, /s_arbgb_header/);
});
