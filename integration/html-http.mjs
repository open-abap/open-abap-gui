import assert from "node:assert/strict";
import {createAbapHtmlHostServer} from "../host/abap-html-server.mjs";

const server = createAbapHtmlHostServer();
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
const base = `http://127.0.0.1:${address.port}`;

try {
  const index = await fetch(`${base}/`);
  assert.equal(index.status, 200);
  assert.match(await index.text(), /ZCL_GG_EX_01/);

  const initial = await fetch(`${base}/ZCL_GG_INTEGRATION_HTML_REPORT`);
  assert.equal(initial.status, 200);
  assert.match(initial.headers.get("content-type"), /^text\/html; charset=utf-8/);
  const initialHtml = await initial.text();
  assert.match(initialHtml, /data-page-kind="SELECTION"/);

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
  assert.match(listHtml, /AA\/0017/);

  const deleted = await fetch(`${base}/session/${encodeURIComponent(sessionId)}`, {method: "DELETE"});
  assert.equal(deleted.status, 204);
} finally {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await server.shutdown();
}

console.log("ABAP HTML HTTP integration: ok");
