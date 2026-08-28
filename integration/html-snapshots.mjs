import assert from "node:assert/strict";
import {createHash} from "node:crypto";

await import("../output/init.mjs");

async function runReport(className) {
  const report = await (new abap.Classes[className]()).constructor_();
  const result = await abap.Classes.ZCL_GG_HOST.run({io_report: report});
  return result.get().html.get();
}

async function runDynpro(className) {
  const program = await (new abap.Classes[className]()).constructor_();
  const result = await abap.Classes.ZCL_GG_HOST_DYNPRO.run({io_program: program, iv_submitted: abap.builtin.abap_false});
  return result.get().html.get();
}

const cases = [
  ["selection", "ZCL_GG_EX_15", runReport, "5788a80b4a48df1c8a30bbcd4d67a5d78e5c216908529654ed173c2e6531f1d2"],
  ["list", "ZCL_GG_EX_01", runReport, "f84134180092fc054e3c84fea5924c70113f911c0a07644e48ea6e8b99f2b9c9"],
  ["dynpro", "ZCL_GG_INTEGRATION_DYNPRO", runDynpro, "12f3e0d63a01fbfd66ef5bffb2129fc050190c7901a38fe6c6aad511cde0b2f1"],
];

for (const [name, className, runner, expectedDigest] of cases) {
  const html = await runner(className);
  assert.match(html, /^<!doctype html>/, name);
  assert.match(html, /<\/html>$/, name);
  const digest = createHash("sha256").update(html).digest("hex");
  assert.equal(digest, expectedDigest, `${name} snapshot changed`);
  console.log(`${name}: ${digest}`);
}

console.log("HTML snapshots: ok");
