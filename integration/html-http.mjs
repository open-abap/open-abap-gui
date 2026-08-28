import assert from "node:assert/strict";
import {createHtmlHostServer} from "../host/html-http.mjs";

let dispatched;
const server = createHtmlHostServer({
  start: async () => ({valid: true, html: "<!doctype html><main>start</main>"}),
  dispatch: async (request) => {
    dispatched = request;
    return {valid: true, html: "<!doctype html><main>next</main>"};
  },
});

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
const base = "http://127.0.0.1:" + address.port;

try {
  const initial = await fetch(base + "/");
  assert.equal(initial.status, 200);
  assert.match(initial.headers.get("content-type"), /^text\/html; charset=utf-8/);
  assert.match(await initial.text(), /<main>start<\/main>/);

  const [concurrentA, concurrentB] = await Promise.all([
    fetch(base + "/"),
    fetch(base + "/"),
  ]);
  assert.equal(concurrentA.status, 200);
  assert.equal(concurrentB.status, 200);

  const next = await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      session_id: "HOST-1",
      page_id: "HOST-1-1",
      gg_action: "LINE:2",
      gg_ucomm: "DETAIL",
    }),
  });
  assert.equal(next.status, 200);
  assert.match(await next.text(), /<main>next<\/main>/);
  assert.equal(dispatched.action, "LINE");
  assert.equal(dispatched.row, 2);
  assert.equal(dispatched.ucomm, "DETAIL");
  assert.equal(dispatched.token, "");

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      gg_action: "SUBMIT",
      values: [{name: "P_CARR", value: "LH", ranges: []}],
      dynpro_values: [{container: "MAIN", name: "P_CARR", row: 0, value: "LH"}],
    }),
  });
  assert.deepEqual(dispatched.dynpro_values, [
    {container: "MAIN", name: "P_CARR", row: 0, value: "LH"},
  ]);

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      session_id: "HOST-1",
      page_id: "HOST-1-1",
      gg_action: "LINE:3|opaque-line-token",
      gg_token: "opaque-line-token",
      gg_ucomm: "DETAIL",
      "gg-cell-ALV-CARR-4": "LH",
      "gg-radio-CARRIER": "LH",
    }),
  });
  assert.equal(dispatched.row, 3);
  assert.equal(dispatched.token, "opaque-line-token");
  assert.deepEqual(dispatched.dynpro_values.find((value) => value.container === "ALV"), {
    container: "ALV", name: "CARR", row: 4, value: "LH",
  });
  assert.deepEqual(dispatched.values.find((value) => value.name === "LH"), {
    name: "LH", value: "X", ranges: [],
  });
  assert.deepEqual(dispatched.dynpro_values.find((value) => value.name === "LH"), {
    container: "", name: "LH", row: 0, value: "X",
  });

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({gg_action: "SCREEN:0200|NEXT"}),
  });
  assert.equal(dispatched.action, "SCREEN");
  assert.equal(dispatched.target, "0200");
  assert.equal(dispatched.ucomm, "NEXT");

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({gg_action: "COMMAND:REFR"}),
  });
  assert.equal(dispatched.action, "COMMAND");
  assert.equal(dispatched.ucomm, "REFR");

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({gg_action: "TAB:DETAIL|TAB_NEXT"}),
  });
  assert.equal(dispatched.action, "TAB");
  assert.equal(dispatched.target, "DETAIL");
  assert.equal(dispatched.ucomm, "TAB_NEXT");

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({gg_action: "VALUE_HELP:CARRID"}),
  });
  assert.equal(dispatched.action, "VALUE_HELP");
  assert.equal(dispatched.target, "CARRID");

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({gg_action: "HELP:S_DATE"}),
  });
  assert.equal(dispatched.action, "HELP");
  assert.equal(dispatched.target, "S_DATE");

  await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({gg_action: "EXIT"}),
  });
  assert.equal(dispatched.action, "EXIT");

  const form = await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      session_id: "HOST-1",
      page_id: "HOST-1-2",
      gg_action: "SUBMIT",
      P_CARR: "LH",
      "S_DATE-LOW": "20260828",
      "S_DATE-SIGN": "I",
    }),
  });
  assert.equal(form.status, 200);
  assert.equal(dispatched.action, "SUBMIT");
  assert.deepEqual(dispatched.values[0], {name: "P_CARR", value: "LH", ranges: []});
  assert.equal(dispatched.values[1].ranges[0].low, "20260828");

  const missing = await fetch(base + "/unknown", {method: "POST"});
  assert.equal(missing.status, 405);
  assert.equal(missing.headers.get("content-type"), "application/json; charset=utf-8");

  const options = await fetch(base + "/", {method: "OPTIONS"});
  assert.equal(options.status, 204);
  assert.match(options.headers.get("allow"), /GET/);

  const invalidJson = await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: "{",
  });
  assert.equal(invalidJson.status, 400);
  assert.equal((await invalidJson.json()).valid, false);
} finally {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
}

console.log("HTML HTTP adapter: ok");
