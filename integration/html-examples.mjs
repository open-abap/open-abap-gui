import assert from "node:assert/strict";
import {createAbapHtmlHostServer} from "../host/abap-html-server.mjs";

const exampleNames = Array.from({length: 58}, (_, index) =>
  `zgg_ex_${String(index + 1).padStart(2, "0")}`);
const exampleEntries = exampleNames.map((name) => ({
  name,
  className: `ZCL_GG_EX_${name.slice(-2)}`,
  path: `/ZCL_GG_EX_${name.slice(-2)}`,
}));
const integrationEntries = [
  {className: "ZCL_GG_DB_HELPER", path: "/ZCL_GG_DB_HELPER", executable: false},
  {className: "ZCL_GG_INTEGRATION_DYNPRO", path: "/ZCL_GG_INTEGRATION_DYNPRO", executable: true},
  {className: "ZCL_GG_INTEGRATION_FAILURE", path: "/ZCL_GG_INTEGRATION_FAILURE", executable: true},
  {className: "ZCL_GG_INTEGRATION_FLIGHTS", path: "/ZCL_GG_INTEGRATION_FLIGHTS", executable: true},
  {className: "ZCL_GG_INTEGRATION_HTML_REPORT", path: "/ZCL_GG_INTEGRATION_HTML_REPORT", executable: true},
  {className: "ZCL_GG_INTEGRATION_INTERACTIVE", path: "/ZCL_GG_INTEGRATION_INTERACTIVE", executable: true},
  {className: "ZCL_GG_INTEGRATION_NAVIGATION", path: "/ZCL_GG_INTEGRATION_NAVIGATION", executable: true},
  {className: "ZCL_GG_INTEGRATION_SELECTION", path: "/ZCL_GG_INTEGRATION_SELECTION", executable: true},
  {className: "ZCL_GG_INTEGRATION_VARIANTS", path: "/ZCL_GG_INTEGRATION_VARIANTS", executable: true},
];
const server = createAbapHtmlHostServer();
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const base = `http://127.0.0.1:${server.address().port}`;

try {
  const indexResponse = await fetch(`${base}/`);
  const indexHtml = await indexResponse.text();
  assert.equal(indexResponse.status, 200);
  assert.match(indexResponse.headers.get("content-type"), /^text\/html; charset=utf-8/);
  for (const {className, path} of exampleEntries) {
    assert.match(indexHtml, new RegExp(`<a href="${path}">${className}</a>`));
  }
  for (const {className, path} of integrationEntries) {
    assert.match(indexHtml, new RegExp(`<a href="${path}">${className}</a>`));
  }

  for (const path of ["/report", "/dynpro", "/zgg_ex_01", "/zgg_ex_58"]) {
    const legacy = await fetch(`${base}${path}`);
    assert.equal(legacy.status, 405, `${path} is still registered`);
  }

  for (const {className, path} of exampleEntries) {
    const response = await fetch(`${base}${path}`);
    const html = await response.text();
    assert.equal(response.status, 200, `${className}: ${html}`);
    assert.match(response.headers.get("content-type"), /^text\/html; charset=utf-8/);
    assert.match(html, /data-session-id="[^"]+"/);
    assert.match(html, /data-page-id="[^"]+"/);

    const sessionId = html.match(/data-session-id="([^"]+)"/)[1];
    const closed = await fetch(`${base}/session/${encodeURIComponent(sessionId)}`, {
      method: "DELETE",
    });
    assert.equal(closed.status, 204, `${className}: unable to close session`);
  }

  for (const {className, path, executable} of integrationEntries) {
    const response = await fetch(`${base}${path}`);
    const html = await response.text();
    assert.equal(response.status, 200, `${className}: ${html}`);
    assert.match(response.headers.get("content-type"), /^text\/html; charset=utf-8/);
    if (executable) {
      const sessionId = html.match(/data-session-id="([^"]+)"/)[1];
      const closed = await fetch(`${base}/session/${encodeURIComponent(sessionId)}`, {
        method: "DELETE",
      });
      assert.equal(closed.status, 204, `${className}: unable to close session`);
    } else {
      assert.match(html, new RegExp(className));
    }
  }
} finally {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await server.shutdown();
}

console.log("ABAP HTML examples and integration classes: all routes ok");
