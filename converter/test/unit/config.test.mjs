import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import { conversionPlan, discoverPrograms, loadTranspileConfig } from "../../src/config.mjs";
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

const BASE = { input_folder: ["src"], input_filter: [], exclude_filter: [], output_folder: "output", options: {} };

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

test("accepts input_folder as a string or an array", async () => {
  const files = { "src/zone.prog.abap": REPORT("zone") };
  const asString = await workspace(files, { ...BASE, input_folder: "src" });
  const stringConfig = await loadTranspileConfig(asString.configPath, { cwd: asString.root });
  assert.equal(stringConfig.valid, true);
  assert.equal(stringConfig.inputFolders.length, 1);

  const asArray = await workspace(files, BASE);
  const arrayConfig = await loadTranspileConfig(asArray.configPath, { cwd: asArray.root });
  assert.equal(arrayConfig.valid, true);
  assert.deepEqual(arrayConfig.inputFolders, stringConfig.inputFolders.map((item) => path.join(asArray.root, path.basename(item))));
});

test("requires input_folder and output_folder", async () => {
  const noInput = await workspace({}, { output_folder: "output", options: {} });
  assert.deepEqual(codes((await loadTranspileConfig(noInput.configPath, { cwd: noInput.root })).diagnostics), ["GGCONV-E112"]);

  const noOutput = await workspace({ "src/zone.prog.abap": REPORT("zone") }, { input_folder: ["src"], options: {} });
  assert.deepEqual(codes((await loadTranspileConfig(noOutput.configPath, { cwd: noOutput.root })).diagnostics), ["GGCONV-E113"]);
});

test("reports an input_folder that does not exist", async () => {
  const missing = await workspace({}, { ...BASE, input_folder: ["nowhere"] });
  const config = await loadTranspileConfig(missing.configPath, { cwd: missing.root });
  assert.equal(config.valid, false);
  assert.ok(config.diagnostics.some((item) => item.code === "GGCONV-E112" && /does not exist/.test(item.message)));
});

test("reports an invalid filter regular expression", async () => {
  const broken = await workspace({ "src/zone.prog.abap": REPORT("zone") }, { ...BASE, input_filter: ["z(one"] });
  const config = await loadTranspileConfig(broken.configPath, { cwd: broken.root });
  assert.equal(config.valid, false);
  assert.ok(config.diagnostics.some((item) => item.code === "GGCONV-E114" && /not a valid regular expression/.test(item.message)));
});

test("derives the generated folder from output_folder and warns when it is not an input folder", async () => {
  const bare = await workspace({ "src/zone.prog.abap": REPORT("zone") }, BASE);
  const bareConfig = await loadTranspileConfig(bare.configPath, { cwd: bare.root });
  assert.equal(bareConfig.generatedFolder, path.join(bare.root, "output_converter"));
  assert.equal(bareConfig.valid, true);
  assert.deepEqual(codes(bareConfig.diagnostics), ["GGCONV-W110"]);

  const listed = await workspace(
    { "src/zone.prog.abap": REPORT("zone") },
    { ...BASE, input_folder: ["src", "output_converter"] },
  );
  const listedConfig = await loadTranspileConfig(listed.configPath, { cwd: listed.root });
  assert.deepEqual(listedConfig.diagnostics, []);
});

test("derives the generated folder from a nested output_folder", async () => {
  const nested = await workspace(
    { "src/zone.prog.abap": REPORT("zone") },
    { ...BASE, output_folder: "build/nested/output" },
  );
  const config = await loadTranspileConfig(nested.configPath, { cwd: nested.root });
  assert.equal(config.generatedFolder, path.join(nested.root, "build", "nested", "output_converter"));
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
  assert.equal(config.generatedFolder, path.join(workspaceRoot, "output_converter"));
  assert.deepEqual((await discoverPrograms(config)).map((item) => item.programName), ["ZONE"]);
});

test("matches filters against absolute posix paths, like abap_transpile", async () => {
  const project = await workspace({
    "src/zalpha.prog.abap": REPORT("zalpha"),
    "src/zbeta.prog.abap": REPORT("zbeta"),
  }, { ...BASE, input_filter: ["zalpha\\.prog\\.abap$"] });
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const programs = await discoverPrograms(config);
  assert.deepEqual(programs.map((item) => item.programName), ["ZALPHA"]);
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

test("applies input_filter before exclude_filter and sorts deterministically", async () => {
  const project = await workspace({
    "src/zalpha.prog.abap": REPORT("zalpha"),
    "src/zbeta.prog.abap": REPORT("zbeta"),
    "src/nested/zgamma.prog.abap": REPORT("zgamma"),
    // Anchoring with ^ cannot work: the filter sees an absolute path.
  }, { ...BASE, input_filter: ["/src/"], exclude_filter: ["zbeta"] });
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const programs = await discoverPrograms(config);
  // The order is the sorted relative path, so a nested folder sorts before a
  // sibling file whose name begins with a later letter.
  assert.deepEqual(programs.map((item) => item.relativePath), ["src/nested/zgamma.prog.abap", "src/zalpha.prog.abap"]);
  assert.ok(!programs.some((item) => item.programName === "ZBETA"));
});

test("de-duplicates overlapping input folders", async () => {
  const project = await workspace(
    { "src/nested/zone.prog.abap": REPORT("zone") },
    { ...BASE, input_folder: ["src", "src/nested"] },
  );
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const programs = await discoverPrograms(config);
  assert.equal(programs.length, 1);
});

test("never discovers its own output, so a second run selects the same programs", async () => {
  const project = await workspace(
    { "src/zone.prog.abap": REPORT("zone") },
    { ...BASE, input_folder: ["src", "output_converter"] },
  );
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const first = await discoverPrograms(config);
  await convertConfiguredPrograms({ config, programs: first });

  const generated = await fs.readdir(config.generatedFolder);
  assert.ok(generated.includes("zcl_one.clas.abap"), `expected generated class, got ${generated.join(", ")}`);

  const second = await discoverPrograms(config);
  assert.deepEqual(second.map((item) => item.relativePath), first.map((item) => item.relativePath));
});

test("conversion plan derives include paths and names, and lets overrides win", async () => {
  const project = await workspace({ "src/zone.prog.abap": REPORT("zone") }, BASE);
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const [program] = await discoverPrograms(config);

  const derived = conversionPlan(config, program, {});
  assert.deepEqual(derived.includePaths, config.inputFolders);
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

test("batch conversion overwrites on a second run and clears stale classes", async () => {
  const project = await workspace(
    { "src/zone.prog.abap": REPORT("zone") },
    { ...BASE, input_folder: ["src", "output_converter"] },
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
  }, { ...BASE, input_folder: ["src", "output_converter"] });
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
  }, { ...BASE, input_folder: ["src", "output_converter"] });
  const config = await loadTranspileConfig(project.configPath, { cwd: project.root });
  const summary = await convertConfiguredPrograms({ config, write: false });
  assert.deepEqual(codes(summary.diagnostics), ["GGCONV-E115"]);

  // Writing would keep one class and silently lose the other.
  await convertConfiguredPrograms({ config });
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
  const result = await runCli(["../scaffold/examples/zgg_ex_001.prog.abap", "--check"]);
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
