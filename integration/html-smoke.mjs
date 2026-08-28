import assert from "node:assert/strict";
import {createAbapHtmlHostServer} from "../host/abap-html-server.mjs";

function metadata(html) {
  return {
    sessionId: html.match(/data-session-id="([^"]+)"/)[1],
    pageId: html.match(/data-page-id="([^"]+)"/)[1],
  };
}

const server = createAbapHtmlHostServer();
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
const base = `http://127.0.0.1:${address.port}`;

try {
  const [first, second] = await Promise.all([
    fetch(`${base}/ZCL_GG_INTEGRATION_HTML_REPORT`),
    fetch(`${base}/ZCL_GG_INTEGRATION_HTML_REPORT`),
  ]);
  const firstHtml = await first.text();
  const secondHtml = await second.text();
  const firstPage = metadata(firstHtml);
  const secondPage = metadata(secondHtml);
  assert.notEqual(firstPage.sessionId, secondPage.sessionId);
  assert.notEqual(firstPage.pageId, secondPage.pageId);

  const firstListResponse = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      session_id: firstPage.sessionId,
      page_id: firstPage.pageId,
      action: "SUBMIT",
      values: [{name: "P_CARR", value: "AA", ranges: []}],
    }),
  });
  assert.equal(firstListResponse.status, 200);
  const firstListHtml = await firstListResponse.text();
  assert.match(firstListHtml, /AA\/0017/);
  assert.doesNotMatch(firstListHtml, /LH\/0400/);
  const firstListPage = metadata(firstListHtml);

  const secondStale = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      session_id: secondPage.sessionId,
      page_id: `${secondPage.sessionId}-999`,
      action: "SUBMIT",
      values: [{name: "P_CARR", value: "LH", ranges: []}],
    }),
  });
  assert.equal(secondStale.status, 409);

  const secondListResponse = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      session_id: secondPage.sessionId,
      page_id: secondPage.pageId,
      gg_action: "SUBMIT",
      P_CARR: "LH",
    }),
  });
  assert.equal(secondListResponse.status, 200);
  const secondListHtml = await secondListResponse.text();
  assert.match(secondListHtml, /LH\/0400/);
  assert.doesNotMatch(secondListHtml, /AA\/0017/);
  const secondListPage = metadata(secondListHtml);

  assert.equal((await fetch(`${base}/session/${firstPage.sessionId}`, {method: "DELETE"})).status, 204);
  const closed = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      session_id: firstPage.sessionId,
      page_id: firstListPage.pageId,
      action: "SUBMIT",
    }),
  });
  assert.equal(closed.status, 400);

  const secondDetail = await fetch(`${base}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      session_id: secondPage.sessionId,
      page_id: secondListPage.pageId,
      gg_action: "LINE:1|H-1-1",
      gg_token: "H-1-1",
    }),
  });
  const secondDetailBody = await secondDetail.text();
  assert.equal(secondDetail.status, 200, secondDetailBody);
  assert.match(secondDetailBody, /LH\/0400/);
} finally {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await server.shutdown();
}

console.log("HTML smoke test: ok");
