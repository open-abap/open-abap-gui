import assert from "node:assert/strict";
import test from "node:test";
import { convertProgram } from "../../src/api.mjs";

const builderCall = (source, name) => source.match(new RegExp(`io_builder->add_\\w+\\( VALUE #\\( name = '${name}'[^\\n]*`))?.[0] ?? "";

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
