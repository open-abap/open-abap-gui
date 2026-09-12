import fs from "node:fs/promises";
import path from "node:path";
import assert from "node:assert/strict";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot } from "./repository.mjs";

const examples = path.join(repositoryRoot, "scaffold", "examples");
const expectedWarningCodes = new Set(["GGCONV-W101"]);
const seen = new Map();

for (let number = 1; number <= 58; number++) {
  const example = String(number).padStart(3, "0");
  const filename = `zgg_ex_${example}.prog.abap`;
  const source = await fs.readFile(path.join(examples, filename), "utf8");
  const result = await convertProgram({ source, filename, mode: "strict" });
  for (const item of result.diagnostics.filter((diagnostic) => diagnostic.severity === "warning")) {
    assert.ok(expectedWarningCodes.has(item.code), `unexpected warning ${item.code} in example ${example}`);
    seen.set(item.code, (seen.get(item.code) ?? 0) + 1);
  }
}

assert.ok(seen.size > 0, "warning gate did not exercise any known warning");
console.log(`warning regression gate passed (${[...seen.entries()].map(([code, count]) => `${code}: ${count}`).join(", ")})`);
