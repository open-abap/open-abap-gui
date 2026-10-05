import assert from "node:assert/strict";
import test from "node:test";
import {verify} from "../verify.mjs";
import {runNode} from "../repository.mjs";

test("full verification runs every suite and shares one generated build", async () => {
  const calls = [];
  await verify({
    runUnit: async () => calls.push("unit"),
    runSuite: async (filename) => calls.push(filename),
    runGenerated: async (options) => calls.push(options),
  });
  assert.deepEqual(calls, [
    "unit", "./run-fixtures.mjs", "./structural-snapshots.mjs", "./examples.mjs",
    "./warnings.mjs", "./hardening.mjs", "./coverage.mjs",
    {transpile: true, behavior: true},
  ]);
});

test("skipping either generated suite still validates the other", async () => {
  for (const skippedSuite of ["transpile", "behavior"]) {
    const builds = [];
    await verify({
      skipped: new Set([skippedSuite]),
      runUnit: async () => {},
      runSuite: async () => {},
      runGenerated: async (options) => builds.push(options),
    });
    assert.deepEqual(builds, [{transpile: skippedSuite !== "transpile", behavior: skippedSuite !== "behavior"}]);
  }
});

test("skipping both generated suites avoids a build", async () => {
  await verify({
    skipped: new Set(["transpile", "behavior"]),
    runUnit: async () => {},
    runSuite: async () => {},
    runGenerated: async () => assert.fail("both generated suites were skipped"),
  });
});

test("a failing in-process suite stops verification before further suites or builds", async () => {
  const failure = new Error("fixture failure");
  let suites = 0;
  await assert.rejects(verify({
    runUnit: async () => {},
    runSuite: async () => { suites++; throw failure; },
    runGenerated: async () => assert.fail("validation ran after a failure"),
  }), (error) => error === failure);
  assert.equal(suites, 1);
});

test("subprocess failures propagate to the verification runner", async () => {
  await assert.rejects(runNode(["-e", "process.exit(7)"]), /exited with code 7/);
});
