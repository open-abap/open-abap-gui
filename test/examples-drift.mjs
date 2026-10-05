// Every example class is the converter's output of its program. This converts
// each examples/zgg_ex_NNN program as `converter/bin/convert.mjs --program
// zgg_ex_NNN --class ZCL_GG_EX_NNN --tcode ZGG_EX_NNN --output ...` does and
// fails when the committed class, its helper classes or its text pool differ.
//
//   node test/examples-drift.mjs            check
//   node test/examples-drift.mjs --update   write the converter's output
//   node test/examples-drift.mjs 058 112    only these examples
import fs from "node:fs/promises";
import path from "node:path";
import { convertConfiguredPrograms } from "../converter/src/batch.mjs";
import { discoverPrograms, loadTranspileConfig } from "../converter/src/config.mjs";
import { emitClassXml } from "../converter/src/emit/class-xml.mjs";
import { loadLibraries } from "../converter/src/libs.mjs";

const update = process.argv.includes("--update");
const only = process.argv.slice(2).filter((item) => /^\d{3}$/.test(item));

// The configuration npm start uses (test/convert-examples.mjs): the
// repository's, with the examples as converter input.
const configPath = "build/abap_transpile.drift.json";
const repositoryConfig = JSON.parse(await fs.readFile("abap_transpile.json", "utf8"));
repositoryConfig.converter = { input_folder: ["examples"], output_folder: "build/generated-examples" };
await fs.mkdir("build", { recursive: true });
await fs.writeFile(configPath, JSON.stringify(repositoryConfig, null, 2), "utf8");
const config = await loadTranspileConfig(configPath);
const libraries = loadLibraries(config);
config.libraryFolders = libraries.folders;

const normalize = (text) => String(text ?? "").replace(/\r\n/g, "\n");
const read = (filename) => fs.readFile(filename, "utf8").then(normalize, () => undefined);

const outdated = [];
let checked = 0;
try {
  const programs = await discoverPrograms(config);
  for (const program of programs) {
    const id = /^ZGG_EX_(\d{3})$/i.exec(program.programName)?.[1];
    if (!id || (only.length && !only.includes(id))) continue;
    const classFile = path.join("examples", `zcl_gg_ex_${id}.clas.abap`);
    // A program without a committed class is converted for npm start only.
    if (!await fs.access(classFile).then(() => true, () => false)) continue;
    const summary = await convertConfiguredPrograms({
      config,
      programs: [program],
      write: false,
      outputFile: classFile,
      overrides: { className: `ZCL_GG_EX_${id}`, transactionCode: `ZGG_EX_${id}` },
    });
    const result = summary.results[0]?.result;
    if (!result?.classSource) {
      outdated.push({ file: classFile, reason: "the converter produced no class" });
      continue;
    }
    checked++;
    const withUnitTests = await fs.access(classFile.replace(/\.clas\.abap$/, ".clas.testclasses.abap")).then(() => true, () => false);
    const expected = [
      { file: classFile, source: result.classSource },
      ...(result.helperSources ?? []).map((helper) => ({
        file: path.join("examples", `${helper.className.toLowerCase()}.clas.abap`),
        source: helper.source,
      })),
    ];
    const classXml = result.reportIR ? emitClassXml(result.reportIR, result.classSource, { withUnitTests }) : undefined;
    if (classXml) expected.push({ file: classFile.replace(/\.clas\.abap$/, ".clas.xml"), source: classXml });
    for (const item of expected) {
      if (await read(item.file) === normalize(item.source)) continue;
      if (update) await fs.writeFile(item.file, item.source, "utf8");
      outdated.push({ file: item.file, reason: update ? "updated" : "differs from the converter's output" });
    }
  }
} finally {
  libraries.cleanup();
}

for (const item of outdated) console.log(`${item.file}: ${item.reason}`);
if (!update && outdated.length) {
  console.error(`${outdated.length} file(s) are not the converter's output; run node test/examples-drift.mjs --update`);
  process.exit(1);
}
console.log(`${checked} example classes are the converter's output`);
