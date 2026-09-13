import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../../src/api.mjs";
import { repositoryRoot } from "../repository.mjs";

const fixture = (name) => fs.readFile(path.join(repositoryRoot, "converter", "test", "fixtures", name), "utf8");

test("regression fixture keeps nested continuation branch context", async () => {
  const result = await convertProgram({
    source: await fixture("regression_nested_continuation.abap.txt"),
    filename: "regression_nested_continuation.prog.abap",
    transactionCode: "ZREGNEST",
  });
  assert.equal(result.supported, true);
  assert.equal(result.diagnostics.some((item) => item.code === "GGCONV-E402"), false);
  assert.match(result.classSource, /after conditional/);
  assert.doesNotMatch(result.classSource, /sibling branch/);
});

test("regression fixture keeps report-only loop legality explicit", async () => {
  const result = await convertProgram({
    source: await fixture("regression_implicit_loop.abap.txt"),
    filename: "regression_implicit_loop.prog.abap",
    mode: "partial",
  });
  assert.equal(result.supported, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E516" && item.message.includes("implicit-header-table LOOP")));
  assert.match(result.classSource, /TODO GGCONV-E501/);
});

test("regression fixture emits dynpro state helpers", async () => {
  const result = await convertProgram({
    source: await fixture("regression_dynpro_state.prog.abap.txt"),
    filename: "regression_dynpro_state.prog.abap",
    dynproMetadata: {
      initialScreen: "0100",
      screens: [{ number: "0100", title: "State", elements: [{ kind: "output", name: "GV_COUNTER" }] }],
      flowLogic: [{ screen: "0100", pbo: [{ name: "STATUS_0100" }], pai: [{ name: "USER_COMMAND_0100" }] }],
      statuses: { "0100": { status: "STATE", activeUcomm: ["NEXT", "BACK"] } },
    },
  });
  assert.equal(result.supported, true);
  assert.match(result.classSource, /METHOD zif_gg_dynpro_v1~process_output_module\./);
  assert.match(result.classSource, /gv_counter = CONV #\(/);
  assert.match(result.classSource, /value = CONV string\( gv_counter \)/);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});
