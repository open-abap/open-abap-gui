import assert from "node:assert/strict";

// The ABAP class is transpiled by the unit gate before this test runs.
await import("../output/init.mjs");
const {zcl_gg_host_html: html} = await import("../output/zcl_gg_host_html.clas.mjs");

const cases = [
  ["empty", "", ""],
  ["unicode", "Grüße 日本語", "Grüße 日本語"],
  ["quotes", "\"'", "&quot;&#39;"],
  ["ampersand", "&", "&amp;"],
  ["angles", "<tag>", "&lt;tag&gt;"],
  ["newline", "line1\nline2", "line1\nline2"],
  ["long", "x".repeat(512), "x".repeat(512)],
];

for (const [name, input, expected] of cases) {
  const actual = (await html.escape_text({iv_text: input})).get();
  assert.equal(actual, expected, name);
}

const document = (await html.document({
  iv_session_id: "S",
  iv_page_id: "P",
  iv_kind: "LIST",
  iv_title: "<title>",
  iv_body: "<main>body</main>",
})).get();
assert.match(document, /^<!doctype html>/);
assert.match(document, /<meta charset="utf-8">/);
assert.match(document, /&lt;title&gt;/);
assert.match(document, /data-page-id="P"/);

console.log("HTML golden primitives: ok");
