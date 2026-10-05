import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot } from "./repository.mjs";

const examples = path.join(repositoryRoot, "examples");

async function dictionaryFilesIn(folder) {
  const found = [];
  for (const entry of await fs.readdir(folder, { withFileTypes: true })) {
    const filename = path.join(folder, entry.name);
    if (entry.isDirectory()) found.push(...await dictionaryFilesIn(filename));
    else if (/\.(?:dtel|doma|tabl|ttyp)\.xml$/.test(entry.name)) found.push(filename);
  }
  return found.sort();
}

// Each program is converted with what lies next to it, as the batch does.
const dictionaryFiles = await dictionaryFilesIn(examples);
const rows = [];
for (let number = 1; number <= 58; number++) {
  const id = String(number).padStart(3, "0");
  const filename = `zgg_ex_${id}.prog.abap`;
  const source = await fs.readFile(path.join(examples, filename), "utf8");
  const result = await convertProgram({
    source,
    filename,
    mode: "strict",
    dynproMetadataFilename: path.join(examples, filename.replace(/\.prog\.abap$/, ".prog.xml")),
    dynproScreenDirectory: examples,
    dictionaryFiles,
  });
  rows.push({
    example: id,
    supported: result.supported,
    programKind: result.reportIR?.programKind,
    diagnostics: result.diagnostics.map((item) => ({ code: item.code, severity: item.severity, construct: item.construct })),
  });
}
console.log(JSON.stringify({ count: rows.length, supported: rows.filter((row) => row.supported).length, deferred: rows.filter((row) => !row.supported).length, rows }, null, 2));
