import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../../src/api.mjs";
import { parseSource, readConfig } from "../../src/parser.mjs";
import { repositoryRoot } from "../repository.mjs";

test("the initial 58 report fixtures are classified deterministically", async () => {
  const directory = path.join(repositoryRoot, "scaffold", "examples");
  const names = (await fs.readdir(directory)).filter((name) => name.endsWith(".prog.abap") && /^zgg_ex_\d{3}\.prog\.abap$/.test(name) && Number(name.slice(7, 10)) >= 1 && Number(name.slice(7, 10)) <= 58).sort();
  assert.ok(names.length >= 58);
  const config = await readConfig(path.join(repositoryRoot, "abaplint.jsonc"));
  for (const name of names) {
    const source = await fs.readFile(path.join(directory, name), "utf8");
    const result = await convertProgram({ source, filename: name, mode: "partial" });
    assert.ok(result.manifest);
    assert.ok(result.classSource);
    const reparsed = parseSource(result.classSource, `${name}.clas.abap`, config);
    assert.deepEqual(reparsed.diagnostics, [], `${name} generated source must reparse`);
    const repeated = await convertProgram({ source, filename: name, mode: "partial" });
    assert.equal(result.classSource, repeated.classSource, `${name} generation must be deterministic`);
    assert.ok(result.diagnostics.every((item) => item.code && item.start && item.end));
  }
});
