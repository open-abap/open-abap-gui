import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot } from "./repository.mjs";

const directory = path.join(repositoryRoot, "scaffold", "examples");
const names = (await fs.readdir(directory)).filter((name) => name.endsWith(".prog.abap")).sort();
const byKind = new Map();
let statementCount = 0;

for (const name of names) {
  const result = await convertProgram({
    source: await fs.readFile(path.join(directory, name), "utf8"),
    filename: name,
    mode: "partial",
  });
  const capabilities = result.reportIR?.capabilities ?? [];
  assert.equal(capabilities.length, result.reportIR?.statements.length, `capability coverage missing statements in ${name}`);
  statementCount += capabilities.length;
  for (const capability of capabilities) {
    const entry = byKind.get(capability.kind) ?? { count: 0, supported: 0, manual: 0, planned: 0, scaffoldGap: 0 };
    entry.count++;
    if (capability.status === "supported") entry.supported++;
    else if (capability.status === "manual") entry.manual++;
    else if (capability.status === "planned") entry.planned++;
    else if (capability.status === "scaffold-gap") entry.scaffoldGap++;
    else assert.fail(`unknown capability status ${capability.status} for ${capability.kind}`);
    byKind.set(capability.kind, entry);
  }
}

const rows = Object.fromEntries([...byKind.entries()].sort(([left], [right]) => left.localeCompare(right)));
console.log(JSON.stringify({ fixtures: names.length, statements: statementCount, byKind: rows }, null, 2));
