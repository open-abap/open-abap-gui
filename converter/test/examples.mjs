import assert from "node:assert/strict";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { convertConfiguredPrograms } from "../src/batch.mjs";
import { converterRoot } from "./repository.mjs";

// Each folder under test/examples is one conversion case: input/ holds the
// ABAP sources, output/ the classes the converter must write for them. The
// input folder is converted the way the CLI converts an abap_transpile.json
// converter.input_folder, so classes in input/ are known globals and programs are found
// by their REPORT header. Pass --update to rewrite output/ from the current
// converter instead of comparing against it.

const examplesRoot = path.join(converterRoot, "test", "examples");
const update = process.argv.includes("--update");

async function listFiles(directory) {
  try {
    return (await fs.readdir(directory)).sort();
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
}

async function convertExample(exampleRoot, targetFolder) {
  const input = path.join(exampleRoot, "input");
  const config = {
    filename: path.join(exampleRoot, "abap_transpile.json"),
    root: exampleRoot,
    inputFolders: [input],
    converterInputFolders: [input],
    libs: [],
    generatedFolder: targetFolder,
  };
  // Manifests are mostly source spans; keeping them out of output/ leaves the
  // generated classes readable, and the classes are what an example is about.
  const manifestFolder = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-example-manifests-"));
  try {
    return await convertConfiguredPrograms({ config, outputFolder: targetFolder, manifestFolder, overrides: { mode: "partial" } });
  } finally {
    await fs.rm(manifestFolder, { recursive: true, force: true });
  }
}

const examples = (await fs.readdir(examplesRoot, { withFileTypes: true }))
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();
assert.ok(examples.length, `no examples found in ${examplesRoot}`);

for (const name of examples) {
  const exampleRoot = path.join(examplesRoot, name);
  const expectedFolder = path.join(exampleRoot, "output");
  const actualFolder = await fs.mkdtemp(path.join(os.tmpdir(), `ggconv-example-${name}-`));
  try {
    const summary = await convertExample(exampleRoot, actualFolder);
    assert.ok(summary.programs.length, `example ${name} has no program in input/`);
    const actualFiles = await listFiles(actualFolder);
    if (update) {
      await fs.rm(expectedFolder, { recursive: true, force: true });
      await fs.mkdir(expectedFolder, { recursive: true });
      for (const file of actualFiles) await fs.copyFile(path.join(actualFolder, file), path.join(expectedFolder, file));
      console.log(`updated example ${name}: ${actualFiles.join(", ")}`);
      continue;
    }
    assert.deepEqual(actualFiles, await listFiles(expectedFolder), `example ${name} produced a different set of files; run with --update to accept`);
    for (const file of actualFiles) {
      const actual = await fs.readFile(path.join(actualFolder, file), "utf8");
      const expected = await fs.readFile(path.join(expectedFolder, file), "utf8");
      assert.equal(actual, expected, `example ${name}: output/${file} changed; run with --update to accept`);
    }
    console.log(`example ${name} matches (${actualFiles.length} files)`);
  } finally {
    await fs.rm(actualFolder, { recursive: true, force: true });
  }
}

console.log(`${update ? "updated" : "verified"} ${examples.length} example${examples.length === 1 ? "" : "s"}`);
