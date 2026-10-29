import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../build/src/api.js";
import { examplePrograms, examplesFolder as directory } from "./repository.mjs";

const names = await examplePrograms();
let unsupported = 0;
for (const name of names) {
  const result = await convertProgram({ source: await fs.readFile(path.join(directory, name), "utf8"), filename: name, includePaths: [directory], mode: "partial" });
  if (!result.classSource || !result.manifest) throw new Error(`fixture did not produce a partial result: ${name}`);
  if (!result.supported) unsupported++;
}
console.log(`converted ${names.length} repository fixtures; ${unsupported} require partial-mode diagnostics`);
