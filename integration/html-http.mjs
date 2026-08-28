import assert from "node:assert/strict";
import {createAbapHtmlHostServer} from "../host/abap-html-server.mjs";

const server = createAbapHtmlHostServer();
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
const base = `http://127.0.0.1:${address.port}`;

try {
  const initial = await fetch(`${base}/ZCL_GG_INTEGRATION_HTML_REPORT`);
  assert.equal(initial.status, 200);
  assert.match(initial.headers.get("content-type"), /^text\/html; charset=utf-8/);
  const initialHtml = await initial.text();
  assert.match(initialHtml, /P_CARR/);

  const sessionId = initialHtml.match(/data-session-id="([^"]+)"/)[1];
  const pageId = initialHtml.match(/data-page-id="([^"]+)"/)[1];
  const list = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      session_id: sessionId,
      page_id: pageId,
      gg_action: "SUBMIT",
      values: [{name: "P_CARR", value: "AA", ranges: []}],
    }),
  });
  assert.equal(list.status, 200);
  const listHtml = await list.text();
  assert.match(listHtml, /0017/);
  const listPageId = listHtml.match(/data-page-id="([^"]+)"/)[1];

  const stale = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      session_id: sessionId,
      page_id: pageId,
      gg_action: "SUBMIT",
      P_CARR: "LH",
    }),
  });
  assert.equal(stale.status, 409);
  assert.equal((await stale.json()).valid, false);

  const form = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      session_id: sessionId,
      page_id: listPageId,
      gg_action: "LINE:2|H-1-2",
      gg_token: "H-1-2",
    }),
  });
  assert.equal(form.status, 200);
  assert.match(await form.text(), /AA\/0018/);

  const invalidJson = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: "{",
  });
  assert.equal(invalidJson.status, 400);
  assert.equal((await invalidJson.json()).valid, false);

  const unknown = await fetch(`${base}/unknown`, {method: "POST"});
  assert.equal(unknown.status, 405);

  const tooLarge = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: "x".repeat(1024 * 1024 + 1),
  });
  assert.equal(tooLarge.status, 400);
  assert.match((await tooLarge.json()).error, /too large/i);

  const deleted = await fetch(`${base}/session/${encodeURIComponent(sessionId)}`, {method: "DELETE"});
  assert.equal(deleted.status, 204);

  const afterDelete = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({session_id: sessionId, page_id: listPageId, gg_action: "SUBMIT"}),
  });
  assert.equal(afterDelete.status, 400);
  assert.equal((await afterDelete.json()).valid, false);
} finally {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await server.shutdown();
}

console.log("ABAP HTML HTTP integration: ok");
