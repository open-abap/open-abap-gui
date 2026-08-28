import assert from "node:assert/strict";

await import("../output/init.mjs");

async function reportHtml(className, extra = {}) {
  const report = await (new abap.Classes[className]()).constructor_();
  const result = await abap.Classes.ZCL_GG_HOST.run({io_report: report, ...extra});
  return result.get().html.get();
}

async function dynproHtml(className) {
  const program = await (new abap.Classes[className]()).constructor_();
  const result = await abap.Classes.ZCL_GG_HOST_DYNPRO.run({
    io_program: program,
    iv_submitted: abap.builtin.abap_false,
  });
  return result.get().html.get();
}

const list = await reportHtml("ZCL_GG_EX_43");
assert.match(list, /<form method="post" action="\/dispatch">/);
assert.match(list, /<button type="submit"[^>]+aria-label="Select line 1"/);
assert.match(list, /data-action-token="[^"]+"/);
assert.doesNotMatch(list, /data-hide-value|name="GV_ID"/);

const selection = await reportHtml("ZCL_GG_EX_17");
assert.match(selection, /<form method="post" action="\/dispatch">/);
assert.match(selection, /data-page-kind="LIST"/);
assert.match(selection, /aria-label="List output"/);

const message = await reportHtml("ZCL_GG_EX_42");
assert.match(message, /class="gg-message gg-error"/);
assert.match(message, /role="alert" aria-live="polite"/);

const dynpro = await dynproHtml("ZCL_GG_INTEGRATION_DYNPRO");
assert.match(dynpro, /<form method="post" action="\/dispatch">/);
assert.match(dynpro, /name="gg_action" value="SUBMIT"/);
assert.match(dynpro, /aria-label="Dynpro/);

console.log("HTML accessibility and source-safety checks: ok");
