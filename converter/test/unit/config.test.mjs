import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import { conversionPlan, discoverPrograms, discoverTransactions, loadTranspileConfig } from "../../src/config.mjs";
import { convertConfiguredPrograms } from "../../src/batch.mjs";
import { converterRoot } from "../repository.mjs";

const REPORT = (name) => `REPORT ${name}.\nSTART-OF-SELECTION.\nWRITE 'hello'.\n`;

async function workspace(files, config) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-config-"));
  for (const [name, contents] of Object.entries(files)) {
    const target = path.join(root, name);
    await fs.mkdir(path.dirname(target), { recursive: true });
    await fs.writeFile(target, contents, "utf8");
  }
  const configPath = path.join(root, "abap_transpile.json");
  if (config !== undefined) {
    await fs.writeFile(configPath, typeof config === "string" ? config : JSON.stringify(config, null, 2), "utf8");
  }
  return { root, configPath };
}

function codes(diagnostics) {
  return diagnostics.map((item) => item.code).sort();
}

const CONVERTER = { input_folder: ["src"], output_folder: "generated" };
const BASE = { input_folder: ["src"], output_folder: "output", converter: CONVERTER, options: {} };
// The generated folder listed as a transpiler input, so no GGCONV-W110.
const LISTED = { ...BASE, input_folder: ["src", "generated"] };

test("reports a missing configuration file instead of throwing", async () => {
  const config = await loadTranspileConfig(path.join(os.tmpdir(), "ggconv-absent", "abap_transpile.json"));
  assert.equal(config.valid, false);
  assert.deepEqual(codes(config.diagnostics), ["GGCONV-E110"]);
});

test("reports malformed JSON and non-object configurations", async () => {
  const broken = await workspace({}, "{ \"input_folder\": [\"src\"], }");
  const brokenConfig = await loadTranspileConfig(broken.configPath, { cwd: broken.root });
  assert.equal(brokenConfig.valid, false);
  assert.deepEqual(codes(brokenConfig.diagnostics), ["GGCONV-E111"]);

  const array = await workspace({}, "[]");
  const arrayConfig = await loadTranspileConfig(array.configPath, { cwd: array.root });
  assert.equal(arrayConfig.valid, false);
  assert.deepEqual(codes(arrayConfig.diagnostics), ["GGCONV-E111"]);
});

test("accepts input_folder and converter.input_folder as a string or an array", async () => {
  const files = { "src/zone.prog.abap": REPORT("zone") };
  const asString = await workspace(files, { ...BASE, input_folder: "src", converter: { ...CONVERTER, input_folder: "src" } });
  const stringConfig = await loadTranspileConfig(asString.configPath, { cwd: asString.root });
  assert.equal(stringConfig.valid, true);
  assert.equal(stringConfig.inputFolders.length, 1);
  assert.equal(stringConfig.converterInputFolders.length, 1);

  const asArray = await workspace(files, BASE);
  const arrayConfig = await loadTranspileConfig(asArray.configPath, { cwd: asArray.root });
  assert.equal(arrayConfig.valid, true);
  assert.deepEqual(arrayConfig.inputFolders, stringConfig.inputFolders.map((item) => path.join(asArray.root, path.basename(item))));
  assert.deepEqual(arrayConfig.converterInputFolders, arrayConfig.inputFolders);
});

test("requires input_folder and the converter folders, but not output_folder", async () => {
  const files = { "src/zone.prog.abap": REPORT("zone") };
  const check = async (config) => {
    const project = await workspace(files, config);
    return codes((await loadTranspileConfig(project.configPath, { cwd: project.root })).diagnostics);
  };
  assert.deepEqual(await check({ converter: CONVERTER, options: {} }), ["GGCONV-E112"]);
  assert.deepEqual(await check({ input_folder: ["src"], options: {} }), ["GGCONV-E118"]);
  assert.deepEqual(await check({ ...BASE, converter: [] }), ["GGCONV-E118"]);
  assert.deepEqual(await check({ ...BASE, converter: { input_folder: ["src"] } }), ["GGCONV-E113"]);
  assert.deepEqual(await check({ ...BASE, converter: { ...CONVERTER, output_folder: " " } }), ["GGCONV-E113"]);
  assert.deepEqual(await check({ ...LISTED, converter: { output_folder: "generated" } }), ["GGCONV-E112"]);
  // The transpiler's own output folder is not the converter's business.
  assert.deepEqual(await check({ input_folder: ["src", "generated"], converter: CONVERTER, options: {} }), []);
});

test("reports an input folder that does not exist, naming the key", async () => {
  const missing = await workspace({}, { ...BASE, input_folder: ["nowhere"], converter: { ...CONVERTER, input_folder: ["reports"] } });
  const config = await loadTranspileConfig(missing.configPath, { cwd: missing.root });
  assert.equal(config.valid, false);
  const absent = config.diagnostics.filter((item) => item.code === "GGCONV-E112" && /does not exist/.test(item.message));
  assert.deepEqual(absent.map((item) => item.construct).sort(), ["converter.input_folder", "input_folder"]);
});

test("takes the generated folder from converter.output_folder and warns when it is not an input folder", async () => {
  const bare = await workspace({ "src/zone.prog.abap": REPORT("zone") }, BASE);
  const bareConfig = await loadTranspileConfig(bare.configPath, { cwd: bare.root });
  assert.equal(bareConfig.generatedFolder, path.join(bare.root, "generated"));
  assert.equal(bareConfig.valid, true);
  assert.deepEqual(codes(bareConfig.diagnostics), ["GGCONV-W110"]);

  const listed = await workspace({ "src/zone.prog.abap": REPORT("zone") }, { ...LISTED, converter: { ...CONVERTER, output_folder: "generated/" } });
  const listedConfig = await loadTranspileConfig(listed.configPath, { cwd: listed.root });
  assert.equal(listedConfig.generatedFolder, path.join(listed.root, "generated"), "a trailing separator is dropped");
  assert.deepEqual(listedConfig.diagnostics, []);
});

// A full run deletes the generated folder, so it must not be, contain or sit
// inside a folder of sources.
test("rejects a converter output folder that overlaps an input folder", async () => {
  const files = { "src/zone.prog.abap": REPORT("zone"), "lib/zlib.prog.abap": "WRITE 'x'.\n" };
  const check = async (config) => {
    const project = await workspace(files, config);
    const loaded = await loadTranspileConfig(project.configPath, { cwd: project.root });
    return loaded.diagnostics.filter((item) => item.code === "GGCONV-E119").map((item) => item.message);
  };
  assert.equal((await check({ ...LISTED, converter: { ...CONVERTER, output_folder: "src" } })).length, 1, "the converter input itself");
  assert.equal((await check({ ...LISTED, converter: { ...CONVERTER, output_folder: "src/generated" } })).length, 1, "inside the converter input");
  assert.ok((await check({ ...LISTED, converter: { ...CONVERTER, output_folder: "." } })).length, "above the converter input");
  const transpilerInput = await check({
    ...BASE,
    input_folder: ["src", "lib", "lib/generated"],
    converter: { ...CONVERTER, output_folder: "lib/generated" },
  });
  assert.equal(transpilerInput.length, 1, "inside a transpiler input other than the generated folder");
  assert.match(transpilerInput[0], /overlaps input_folder entry lib;/);
  assert.deepEqual(await check(LISTED), [], "the generated folder listed as a transpiler input is expected");
});

// abap_transpile globs `<input_folder>/**` from process.cwd(), so a config
// stored away from the sources it names still resolves them against the
// working directory. The checked-in gg-gui config depends on exactly this: it
// lives in converter/gg-gui-validation/ and names `src` at the repository root.
test("resolves folders against the working directory, like abap_transpile", async () => {
  const workspaceRoot = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-cwd-"));
  await fs.mkdir(path.join(workspaceRoot, "src"), { recursive: true });
  await fs.mkdir(path.join(workspaceRoot, "nested", "deep"), { recursive: true });
  await fs.writeFile(path.join(workspaceRoot, "src", "zone.prog.abap"), REPORT("zone"), "utf8");
  const configPath = path.join(workspaceRoot, "nested", "deep", "abap_transpile.json");
  await fs.writeFile(configPath, JSON.stringify(BASE), "utf8");

  const config = await loadTranspileConfig(configPath, { cwd: workspaceRoot });
  assert.equal(config.root, workspaceRoot);
  assert.deepEqual(config.inputFolders, [path.join(workspaceRoot, "src")], "input_folder is relative to the working directory");
  assert.deepEqual(config.converterInputFolders, [path.join(workspaceRoot, "src")], "so is converter.input_folder");
  assert.equal(config.generatedFolder, path.join(workspaceRoot, "generated"));
  assert.deepEqual((await discoverPrograms(config)).map((item) => item.programName), ["ZONE"]);
});

// The transpiler's filters choose what abap_transpile compiles; the converter
// input is a folder of its own, so they do not narrow it.
test("discovers programs only in converter.input_folder, ignoring the transpiler's filters", async () => {
  const project = await workspace({
    "reports/zalpha.prog.abap": REPORT("zalpha"),
    "reports/zbeta.prog.abap": REPORT("zbeta"),
    "src/zother.prog.abap": REPORT("zother"),
  }, {
    ...BASE,
    input_filter: ["zalpha\\.prog\\.abap$", "z(broken"],
    exclude_filter: ["zbeta"],
    converter: { ...CONVERTER, input_folder: ["reports"] },
  });
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  assert.equal(config.valid, true, "a filter the converter does not use is not validated");
  const programs = await discoverPrograms(config);
  assert.deepEqual(programs.map((item) => item.programName), ["ZALPHA", "ZBETA"]);
});

test("ignores configuration keys the converter does not use", async () => {
  const extended = await workspace({ "src/zone.prog.abap": REPORT("zone") }, {
    ...BASE,
    libs: [{ url: "https://example.invalid/lib" }],
    write_unit_tests: true,
    some_future_transpiler_key: { nested: true },
  });
  const config = await loadTranspileConfig(extended.configPath, { cwd: extended.root });
  assert.equal(config.valid, true);
  assert.deepEqual(codes(config.diagnostics), ["GGCONV-W110"]);
});

test("discovers executable programs and skips include-only sources", async () => {
  const project = await workspace({
    "src/zreport.prog.abap": REPORT("zreport"),
    "src/zmodule.prog.abap": "PROGRAM zmodule.\n",
    "src/zinclude.prog.abap": "WRITE 'include body'.\n",
    "src/zhelper.clas.abap": "CLASS zhelper DEFINITION.\nENDCLASS.\n",
  }, BASE);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const programs = await discoverPrograms(config);
  assert.deepEqual(programs.map((item) => item.programName), ["ZMODULE", "ZREPORT"]);
  assert.deepEqual(programs.map((item) => item.relativePath), ["src/zmodule.prog.abap", "src/zreport.prog.abap"]);
});

test("sorts discovered programs deterministically", async () => {
  const project = await workspace({
    "src/zalpha.prog.abap": REPORT("zalpha"),
    "src/nested/zgamma.prog.abap": REPORT("zgamma"),
  }, BASE);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const programs = await discoverPrograms(config);
  // The order is the sorted relative path, so a nested folder sorts before a
  // sibling file whose name begins with a later letter.
  assert.deepEqual(programs.map((item) => item.relativePath), ["src/nested/zgamma.prog.abap", "src/zalpha.prog.abap"]);
});

test("de-duplicates overlapping converter input folders", async () => {
  const project = await workspace(
    { "src/nested/zone.prog.abap": REPORT("zone") },
    { ...BASE, converter: { ...CONVERTER, input_folder: ["src", "src/nested"] } },
  );
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const programs = await discoverPrograms(config);
  assert.equal(programs.length, 1);
});

test("conversion plan derives include paths and names, and lets overrides win", async () => {
  const project = await workspace({
    "reports/zone.prog.abap": REPORT("zone"),
    "src/zhelper.clas.abap": "CLASS zhelper DEFINITION.\nENDCLASS.\n",
  }, { ...BASE, input_folder: ["src", "reports"], converter: { ...CONVERTER, input_folder: ["reports"] } });
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const [program] = await discoverPrograms(config);

  const derived = conversionPlan(config, program, {});
  assert.deepEqual(derived.includePaths, [path.join(config.root, "reports"), path.join(config.root, "src")],
    "the converter input first, then the transpiler inputs, each once");
  assert.equal(derived.configPath, path.join(config.root, "abaplint.jsonc"));
  assert.equal(derived.className, undefined);
  assert.equal(derived.mode, "strict");
  assert.ok(!("description" in derived));

  const overridden = conversionPlan(config, program, {
    className: (name) => `ZCL_CV_${name}`,
    transactionCode: "ZTX",
    mode: "partial",
  });
  assert.equal(overridden.className, "ZCL_CV_ZONE");
  assert.equal(overridden.transactionCode, "ZTX");
  assert.equal(overridden.mode, "partial");
});

test("takes the transaction code and text from a transaction that starts the program", async () => {
  const tran = (tcode, program, text) => [
    '<?xml version="1.0" encoding="utf-8"?>',
    '<abapGit version="v1.0.0" serializer="LCL_OBJECT_TRAN" serializer_version="v1.0.0">',
    ' <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">',
    "  <asx:values>",
    `   <TSTC><TCODE>${tcode}</TCODE>${program ? `<PGMNA>${program}</PGMNA>` : ""}</TSTC>`,
    `   <TSTCT><SPRSL>E</SPRSL><TCODE>${tcode}</TCODE><TTEXT>${text}</TTEXT></TSTCT>`,
    "  </asx:values>",
    " </asx:abap>",
    "</abapGit>",
  ].join("\n");
  const project = await workspace({
    "src/zreport_with_a_very_long_name.prog.abap": REPORT("zreport_with_a_very_long_name"),
    "src/zlong_b.tran.xml": tran("ZLONG_B", "ZREPORT_WITH_A_VERY_LONG_NAME", "Second"),
    "src/zlong_a.tran.xml": tran("ZLONG_A", "ZREPORT_WITH_A_VERY_LONG_NAME", "First"),
    "src/zparam.tran.xml": tran("ZPARAM", undefined, "Parameter transaction"),
    "src/zbroken.tran.xml": "<abapGit>",
  }, BASE);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const transactions = await discoverTransactions(config);
  assert.deepEqual([...transactions.keys()], ["ZREPORT_WITH_A_VERY_LONG_NAME"]);
  assert.deepEqual(transactions.get("ZREPORT_WITH_A_VERY_LONG_NAME"), {
    transactionCode: "ZLONG_A",
    program: "ZREPORT_WITH_A_VERY_LONG_NAME",
    description: "First",
  });

  const [program] = await discoverPrograms(config);
  const derived = conversionPlan(config, program, { transactions });
  assert.equal(derived.transactionCode, "ZLONG_A");
  assert.equal(derived.description, "First");
  assert.ok(!("transactions" in derived));
  const overridden = conversionPlan(config, program, { transactions, transactionCode: "ZOWN", description: "Own" });
  assert.equal(overridden.transactionCode, "ZOWN");
  assert.equal(overridden.description, "Own");

  const summary = await convertConfiguredPrograms({ config, write: false });
  assert.equal(summary.programs[0].transactionCode, "ZLONG_A");
  assert.ok(!summary.programs[0].diagnostics.some((item) => item.code === "GGCONV-W105"));
});

test("batch conversion overwrites on a second run and clears stale classes", async () => {
  const project = await workspace(
    { "src/zone.prog.abap": REPORT("zone") },
    LISTED,
  );
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const first = await convertConfiguredPrograms({ config });
  const generatedFile = path.join(config.generatedFolder, "zcl_one.clas.abap");
  const before = await fs.readFile(generatedFile, "utf8");

  await fs.writeFile(path.join(config.generatedFolder, "zcl_stale.clas.abap"), "* stale\n", "utf8");
  const second = await convertConfiguredPrograms({ config });

  assert.equal(await fs.readFile(generatedFile, "utf8"), before);
  assert.deepEqual(second.programs, first.programs);
  const remaining = await fs.readdir(config.generatedFolder);
  assert.ok(!remaining.includes("zcl_stale.clas.abap"), "the generated folder should not keep classes no program produces");
});

test("converting a subset keeps the classes the subset does not produce", async () => {
  const project = await workspace({
    "src/zone.prog.abap": REPORT("zone"),
    "src/ztwo.prog.abap": REPORT("ztwo"),
  }, LISTED);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  await convertConfiguredPrograms({ config });
  assert.deepEqual((await fs.readdir(config.generatedFolder)).filter((name) => name.endsWith(".clas.abap")).sort(),
    ["zcl_one.clas.abap", "zcl_two.clas.abap"]);

  const [first] = await discoverPrograms(config);
  await convertConfiguredPrograms({ config, programs: [first], clear: false });
  assert.deepEqual((await fs.readdir(config.generatedFolder)).filter((name) => name.endsWith(".clas.abap")).sort(),
    ["zcl_one.clas.abap", "zcl_two.clas.abap"], "a subset run must not delete the other program's class");
});

test("batch conversion reports a target class produced by two programs", async () => {
  const project = await workspace({
    "src/zone.prog.abap": REPORT("zone"),
    "src/other/zone.prog.abap": REPORT("zone"),
  }, LISTED);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const summary = await convertConfiguredPrograms({ config, write: false });
  assert.deepEqual(codes(summary.diagnostics), ["GGCONV-E115"]);

  // Writing would keep one class and silently lose the other.
  await convertConfiguredPrograms({ config });
  await assert.rejects(() => fs.readdir(config.generatedFolder), "a colliding run must not write a partial class set");
});

const GLOBAL_CLASS = (name) => `CLASS ${name} DEFINITION PUBLIC CREATE PUBLIC.\n  PUBLIC SECTION.\nENDCLASS.\nCLASS ${name} IMPLEMENTATION.\nENDCLASS.\n`;
const REPORT_WITH_LOCAL_CLASS = (name) => [
  `REPORT ${name}.`,
  "CLASS lcl_helper DEFINITION.",
  "  PUBLIC SECTION.",
  "    METHODS run.",
  "ENDCLASS.",
  "CLASS lcl_helper IMPLEMENTATION.",
  "  METHOD run.",
  "  ENDMETHOD.",
  "ENDCLASS.",
  "START-OF-SELECTION.",
  "  NEW lcl_helper( )->run( ).",
  "",
].join("\n");

test("batch conversion renames a default class name that already exists in the sources", async () => {
  const project = await workspace({
    "src/zone.prog.abap": REPORT("zone"),
    "src/lib/zcl_one.clas.abap": GLOBAL_CLASS("zcl_one"),
  }, LISTED);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  for (const run of ["first", "second"]) {
    const summary = await convertConfiguredPrograms({ config });
    const [program] = summary.programs;
    assert.equal(program.supported, true, JSON.stringify(program.diagnostics));
    assert.equal(program.targetClass, "ZCL_ONE_1", run);
    const warning = program.diagnostics.find((item) => item.code === "GGCONV-W106");
    assert.equal(warning?.severity, "warning", run);
    assert.match(warning.message, /ZCL_ONE already exists in src\/lib\/zcl_one\.clas\.abap/);
    // abaplint would accept a second file for ZCL_ONE and compile whichever it
    // read first; the previous run's ZCL_ONE_1 must not push the name further.
    assert.deepEqual(await fs.readdir(config.generatedFolder), ["zcl_one_1.clas.abap"], run);
    assert.match(await fs.readFile(path.join(config.generatedFolder, "zcl_one_1.clas.abap"), "utf8"), /program = 'ZONE'/);
  }
});

test("batch conversion keeps an explicit class name that already exists an error", async () => {
  const project = await workspace({
    "src/zone.prog.abap": REPORT("zone"),
    "src/lib/zcl_one.clas.abap": GLOBAL_CLASS("zcl_one"),
  }, LISTED);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  for (const mode of ["strict", "partial"]) {
    const summary = await convertConfiguredPrograms({ config, overrides: { mode, className: "ZCL_ONE" } });
    assert.ok(summary.programs[0].diagnostics.some((item) => item.code === "GGCONV-E106"), mode);
    await assert.rejects(() => fs.access(path.join(config.generatedFolder, "zcl_one.clas.abap")), mode);
  }
});

test("batch conversion names helper classes around existing classes", async () => {
  const project = await workspace({
    "src/zone.prog.abap": REPORT_WITH_LOCAL_CLASS("zone"),
    "src/zcl_one_h1.clas.abap": GLOBAL_CLASS("zcl_one_h1"),
  }, LISTED);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const summary = await convertConfiguredPrograms({ config });
  assert.equal(summary.programs[0].supported, true, JSON.stringify(summary.programs[0].diagnostics));
  const written = (await fs.readdir(config.generatedFolder)).sort();
  assert.deepEqual(written, ["zcl_one.clas.abap", "zcl_one_h1_1.clas.abap"]);
});

test("batch conversion reports a helper class produced by two programs", async () => {
  // Helper names use the first 24 characters of the target class, which these share.
  const project = await workspace({
    "src/zlong_report_name_abcd_a.prog.abap": REPORT_WITH_LOCAL_CLASS("zlong_report_name_abcd_a"),
    "src/zlong_report_name_abcd_b.prog.abap": REPORT_WITH_LOCAL_CLASS("zlong_report_name_abcd_b"),
  }, LISTED);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const summary = await convertConfiguredPrograms({ config, overrides: { transactionCode: (name) => name.slice(-8) } });
  assert.deepEqual(codes(summary.diagnostics), ["GGCONV-E115"]);
  assert.match(summary.diagnostics[0].message, /ZCL_LONG_REPORT_NAME_ABC_H1/);
  await assert.rejects(() => fs.readdir(config.generatedFolder), "a colliding run must not write a partial class set");
});

function runCli(args, cwd = converterRoot) {
  return new Promise((resolve) => {
    const child = spawn(process.execPath, [path.join(converterRoot, "bin", "convert.mjs"), ...args], { cwd });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.once("exit", (code) => resolve({ code, stdout, stderr }));
  });
}

test("the CLI rejects a positional argument and names the replacement", async () => {
  const result = await runCli(["../examples/zgg_ex_001.prog.abap", "--check"]);
  assert.equal(result.code, 2);
  assert.match(result.stderr, /takes no positional arguments/);
  assert.match(result.stderr, /--program/);
});

test("the CLI requires exactly one --program for single-program options", async () => {
  const config = path.join(converterRoot, "test", "fixtures", "check", "abap_transpile.json");
  const none = await runCli(["--config", config, "--class", "ZCL_X", "--check"]);
  assert.equal(none.code, 2);
  assert.match(none.stderr, /require exactly one --program/);

  const one = await runCli(["--config", config, "--program", "ZGG_EX_001", "--class", "ZCL_X", "--check"]);
  assert.equal(one.code, 0);
  assert.match(one.stdout, /"targetClass": "ZCL_X"/);
});

test("the CLI converts every selected program and exits 0 when all are supported", async () => {
  const config = path.join(converterRoot, "test", "fixtures", "check", "abap_transpile.json");
  const result = await runCli(["--config", config, "--check"]);
  assert.equal(result.code, 0);
  const parsed = JSON.parse(result.stdout);
  assert.equal(parsed.summary.programCount, 1, "npm run check must stay a one-program smoke test");
  assert.equal(parsed.summary.supportedCount, 1);
});
