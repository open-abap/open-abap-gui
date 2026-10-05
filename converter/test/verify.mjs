import fs from "node:fs/promises";
import path from "node:path";
import {converterRoot, isMain, runNode} from "./repository.mjs";

const suites = [
  ["fixtures", "./run-fixtures.mjs"],
  ["structural", "./structural-snapshots.mjs"],
  // Compare committed snapshots; accepting changes remains examples:update.
  ["examples", "./examples.mjs"],
  ["warnings", "./warnings.mjs"],
  ["hardening", "./hardening.mjs"],
  ["coverage", "./coverage.mjs"],
];

export async function verify({skipped = new Set(), runUnit, runSuite, runGenerated} = {}) {
  runUnit ??= async () => {
    const files = [];
    for (const folder of ["unit", "integration"]) {
      const directory = path.join(converterRoot, "test", folder);
      for (const name of (await fs.readdir(directory)).sort()) {
        if (name.endsWith(".test.mjs")) files.push(path.join(directory, name));
      }
    }
    await runNode(["--test", ...files], {cwd: converterRoot});
  };
  runSuite ??= (filename) => import(filename);
  runGenerated ??= async (options) => {
    const {runGeneratedValidation} = await import("./generated-validation.mjs");
    await runGeneratedValidation(options);
  };

  const run = async (name, action) => {
    console.log(`\n=== ${name}${skipped.has(name) ? " (skipped)" : ""} ===`);
    if (!skipped.has(name)) {
      const started = performance.now();
      await action();
      console.log(`${name} passed (${((performance.now() - started) / 1000).toFixed(1)}s)`);
    }
  };
  await run("test:unit", runUnit);
  // These suites have module-local state and share converter/parser imports.
  for (const [name, filename] of suites) await run(name, () => runSuite(filename));
  for (const name of ["transpile", "behavior"]) {
    if (skipped.has(name)) console.log(`\n=== ${name} (skipped) ===`);
  }
  const transpile = !skipped.has("transpile");
  const behavior = !skipped.has("behavior");
  if (transpile || behavior) {
    const started = performance.now();
    await runGenerated({transpile, behavior});
    console.log(`generated validation passed (${((performance.now() - started) / 1000).toFixed(1)}s)`);
  }
  console.log("\nconverter verification passed");
}

if (isMain(import.meta.url)) {
  // Local iteration only: CI verifies every suite with no skips.
  const skipped = new Set();
  const names = new Set(["test:unit", ...suites.map(([name]) => name), "transpile", "behavior"]);
  for (let index = 2; index < process.argv.length; index += 2) {
    const name = process.argv[index + 1];
    if (process.argv[index] !== "--skip" || !names.has(name)) throw new Error("Expected --skip followed by a known suite name");
    skipped.add(name);
  }
  await verify({skipped});
}
