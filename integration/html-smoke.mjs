import assert from "node:assert/strict";
import {createHtmlHostServer} from "../host/html-http.mjs";

let nextSession = 0;
const sessions = new Map();

function page(sessionId, pageId, label) {
  return `<!doctype html><html><body><main data-session-id="${sessionId}" data-page-id="${pageId}">${label}</main></body></html>`;
}

const server = createHtmlHostServer({
  start: async () => {
    const sessionId = `SMOKE-${++nextSession}`;
    sessions.set(sessionId, 1);
    return {valid: true, html: page(sessionId, "1", "start")};
  },
  dispatch: async (request) => {
    const current = sessions.get(request.session_id);
    if (current === undefined) return {valid: false, error: "Unknown host session"};
    if (request.page_id !== String(current)) return {valid: false, error: "Stale host page"};
    const nextPage = current + 1;
    sessions.set(request.session_id, nextPage);
    return {valid: true, html: page(request.session_id, String(nextPage), request.action)};
  },
  close: async (sessionId) => sessions.delete(sessionId),
});

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
const base = `http://127.0.0.1:${address.port}`;

try {
  const [first, second] = await Promise.all([fetch(base + "/"), fetch(base + "/")]);
  const firstHtml = await first.text();
  const secondHtml = await second.text();
  assert.match(firstHtml, /SMOKE-1/);
  assert.match(secondHtml, /SMOKE-2/);

  const firstNext = await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      session_id: "SMOKE-1", page_id: "1", gg_action: "SUBMIT",
    }),
  });
  assert.equal(firstNext.status, 200);
  assert.match(await firstNext.text(), /data-page-id="2"/);

  const secondStale = await fetch(base + "/dispatch", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({session_id: "SMOKE-2", page_id: "0", action: "SUBMIT"}),
  });
  assert.equal(secondStale.status, 409);

  assert.equal((await fetch(base + "/session/SMOKE-1", {method: "DELETE"})).status, 204);
  assert.equal(sessions.has("SMOKE-1"), false);
} finally {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
}

console.log("HTML smoke test: ok");
