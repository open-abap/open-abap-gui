import fs from "node:fs/promises";
import path from "node:path";

// The web build also shows the converter examples, so their screens are part
// of the screenshots and the visual diffs. Each example's checked-in output is
// compiled as it is, with the classes and dictionary objects of its input; the
// report programs themselves are not compiled. test/examples.mjs keeps output/
// equal to what the converter writes.
// Writes build/abap_transpile.web.json: abap_transpile.json plus these sources.

const examplesRoot = "converter/test/examples";
const sourceFolder = "build/converter-examples";
const configPath = "build/abap_transpile.web.json";

// Examples whose output does not compile here, each with the reason.
const skipped = new Map([
  ["unknown_types_passthrough", "keeps types the converter cannot resolve"],
  ["unresolved_call_todo", "keeps a call the converter cannot resolve"],
  ["selection_screen_types", "needs the SAP table SFLIGHT"],
  ["open_sql_loop", "needs the SAP table SFLIGHT and its data elements"],
  ["include_type_structure", "needs the dictionary table ZLOG"],
  ["interactive_list", "converter defect: the HIDE field read in AT LINE-SELECTION does not compile"],
  ["set_handler_global_event", "converter defect: the handler class is created without its io_owner"],
]);

async function copyFiles(from, to, include) {
  for (const entry of await fs.readdir(from, { withFileTypes: true })) {
    if (!entry.isFile() || !include(entry.name)) continue;
    await fs.copyFile(path.join(from, entry.name), path.join(to, entry.name));
  }
}

await fs.rm(sourceFolder, { recursive: true, force: true });
const included = [];
for (const entry of (await fs.readdir(examplesRoot, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name))) {
  if (!entry.isDirectory()) continue;
  if (skipped.has(entry.name)) {
    console.log(`skipped converter example ${entry.name}: ${skipped.get(entry.name)}`);
    continue;
  }
  const target = path.join(sourceFolder, entry.name);
  await fs.mkdir(target, { recursive: true });
  await copyFiles(path.join(examplesRoot, entry.name, "output"), target, () => true);
  await copyFiles(path.join(examplesRoot, entry.name, "input"), target, (name) => !/\.prog\./i.test(name) && !/\.tran\./i.test(name));
  included.push(entry.name);
}

const config = JSON.parse(await fs.readFile("abap_transpile.json", "utf8"));
config.input_folder.push(sourceFolder);
await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf8");
console.log(`added ${included.length} converter examples to ${configPath}`);
