import assert from "node:assert/strict";
import {createAbapHtmlRuntime} from "../host/abap-html-runtime.mjs";

const report = createAbapHtmlRuntime({entryPoint: "ZCL_GG_INTEGRATION_HTML_REPORT"});
const dynpro = createAbapHtmlRuntime({entryPoint: "ZCL_GG_INTEGRATION_DYNPRO"});

try {
  const selection = await report.start();
  assert.equal(selection.valid, true, selection.error);
  assert.equal(selection.page_kind, "SELECTION");
  assert.match(selection.html, /P_CARR/);

  const list = await report.dispatch({
    session_id: selection.session_id,
    page_id: selection.page_id,
    action: "SUBMIT",
    values: [{name: "P_CARR", value: "AA", ranges: []}],
    dynpro_values: [],
  });
  assert.equal(list.valid, true, list.error);
  assert.equal(list.page_kind, "LIST");
  assert.match(list.html, /0017/);

  const stale = await report.dispatch({
    session_id: selection.session_id,
    page_id: selection.page_id,
    action: "SUBMIT",
    values: [{name: "P_CARR", value: "LH", ranges: []}],
    dynpro_values: [],
  });
  assert.equal(stale.valid, false);
  assert.match(stale.error, /Stale/);

  const dynproStart = await dynpro.start();
  assert.equal(dynproStart.valid, true, dynproStart.error);
  assert.equal(dynproStart.page_kind, "DYNPRO");
  assert.match(dynproStart.html, /P_INPUT/);

  const dynproNext = await dynpro.dispatch({
    session_id: dynproStart.session_id,
    page_id: dynproStart.page_id,
    action: "COMMAND",
    ucomm: "NEXT",
    values: [],
    dynpro_values: [{container: "", name: "P_INPUT", row: 0, value: "AA-0017"}],
  });
  assert.equal(dynproNext.valid, true, dynproNext.error);
  assert.equal(dynproNext.page_kind, "DYNPRO");
  assert.match(dynproNext.html, /Flight result/);
  assert.match(dynproNext.html, /AA-0017/);

  await report.close(selection.session_id);
  const closed = await report.dispatch({
    session_id: selection.session_id,
    page_id: list.page_id,
    action: "SUBMIT",
    values: [],
    dynpro_values: [],
  });
  assert.equal(closed.valid, false);
  assert.match(closed.error, /session/i);
} finally {
  await report.clear();
  await dynpro.clear();
}

console.log("ABAP HTML runtime bridge: ok");
