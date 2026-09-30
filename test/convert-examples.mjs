import fs from "node:fs/promises";
import { convertConfiguredPrograms } from "../converter/src/batch.mjs";
import { discoverPrograms, loadTranspileConfig } from "../converter/src/config.mjs";

// npm start shows every example in the workbench. An example program with no
// hand-written zcl_gg_ex_NNN counterpart is converted into build/, and a copy
// of abap_transpile.json that also compiles build/ is written for npm start.
const configPath = "build/abap_transpile.start.json";
const config = JSON.parse(await fs.readFile("abap_transpile.json", "utf8"));
config.input_folder.push("build/generated-examples");
config.converter = { input_folder: ["examples"], output_folder: "build/generated-examples" };
await fs.mkdir("build", { recursive: true });
await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf8");

const loaded = await loadTranspileConfig(configPath);
const examples = await fs.readdir("examples");
const programs = (await discoverPrograms(loaded)).filter((program) =>
  !examples.includes(`${program.programName.toLowerCase().replace(/^zgg_/, "zcl_gg_")}.clas.abap`));
const summary = await convertConfiguredPrograms({ config: loaded, programs });
for (const program of summary.programs) {
  console.log(`${program.supported ? "converted" : "skipped"} ${program.filename}`);
}
