import assert from "node:assert/strict";
import test from "node:test";
import { execFileSync } from "node:child_process";
import fs from "node:fs/promises";
import { existsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { discoverGlobalClassNames, discoverPrograms, loadTranspileConfig } from "../../src/config.mjs";
import { convertConfiguredPrograms } from "../../src/batch.mjs";
import { loadLibraries } from "../../src/libs.mjs";

const MAIN = "REPORT zmain.\nINCLUDE zlib_inc.\nSTART-OF-SELECTION.\nWRITE 'hello'.\n";
const LIB_FILES = {
  "src/sub/zlib_inc.prog.abap": "WRITE 'from lib'.\n",
  "src/zlib_report.prog.abap": "REPORT zlib_report.\nWRITE 'lib'.\n",
};
const BASE = { input_folder: ["src", "output_converter"], output_folder: "output", options: {} };

async function writeFiles(root, files) {
  for (const [name, contents] of Object.entries(files)) {
    const target = path.join(root, name);
    await fs.mkdir(path.dirname(target), { recursive: true });
    await fs.writeFile(target, contents, "utf8");
  }
}

async function project(libs, extraFiles = {}) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-libs-"));
  await writeFiles(root, { "src/zmain.prog.abap": MAIN, ...extraFiles });
  const configPath = path.join(root, "abap_transpile.json");
  await fs.writeFile(configPath, JSON.stringify({ ...BASE, libs }), "utf8");
  return { root, config: await loadTranspileConfig(configPath, { cwd: root }) };
}

async function convertWithLibraries(config) {
  const libraries = loadLibraries(config);
  config.libraryFolders = libraries.folders;
  try {
    return { libraries, summary: await convertConfiguredPrograms({ config, write: false }) };
  } finally {
    libraries.cleanup();
  }
}

test("parses libs and reports entries it cannot use", async () => {
  const { config } = await project([
    { url: "https://example.invalid/lib", exclude_filter: ["zskip"] },
    { folder: "deps/lib", files: "/src/**/*.abap" },
    {},
    "not an object",
  ]);
  assert.equal(config.valid, false);
  assert.deepEqual(config.diagnostics.map((item) => item.code), ["GGCONV-E117", "GGCONV-E117"]);
  assert.equal(config.libs.length, 2);
  assert.deepEqual(config.libs[0].files, ["/src/**"]);
  assert.ok(config.libs[0].excludeFilters[0].test("/x/ZSKIP.prog.abap"));
  assert.deepEqual(config.libs[1].files, ["/src/**/*.abap"]);

  const notArray = await project({ url: "https://example.invalid/lib" });
  assert.deepEqual(notArray.config.diagnostics.map((item) => item.code), ["GGCONV-E117"]);
});

test("resolves includes from a lib folder without converting the lib's programs", async () => {
  const { config } = await project([{ folder: "deps/lib" }], Object.fromEntries(
    Object.entries(LIB_FILES).map(([name, contents]) => [`deps/lib/${name}`, contents])));
  assert.equal(config.valid, true);

  const withoutLibs = await convertConfiguredPrograms({ config, write: false });
  assert.ok(withoutLibs.programs[0].diagnostics.some((item) => item.code === "GGCONV-E102"), "the include is only in the lib");

  const { libraries, summary } = await convertWithLibraries(config);
  assert.deepEqual(libraries.folders, [path.join(config.root, "deps", "lib", "src"), path.join(config.root, "deps", "lib", "src", "sub")]);
  assert.deepEqual(summary.programs.map((item) => item.programName), ["ZMAIN"]);
  assert.ok(!summary.programs[0].diagnostics.some((item) => item.code === "GGCONV-E102"));
  assert.ok(existsSync(path.join(config.root, "deps", "lib")), "a lib folder is not the converter's to delete");
});

test("applies the lib files patterns and exclude_filter", async () => {
  const { config } = await project(
    [{ folder: "deps/lib", files: ["/src/sub/**"], exclude_filter: ["zlib_other"] }],
    {
      "deps/lib/src/sub/zlib_inc.prog.abap": "WRITE 'x'.\n",
      "deps/lib/src/sub/skipped/zlib_other.prog.abap": "WRITE 'x'.\n",
      "deps/lib/src/zlib_report.prog.abap": "REPORT zlib_report.\n",
    },
  );
  const libraries = loadLibraries(config);
  assert.deepEqual(libraries.folders, [path.join(config.root, "deps", "lib", "src", "sub")]);
});

test("lets the batch register handlers of global classes from the input folders and libs", async () => {
  const CALLER = [
    "REPORT zmain.",
    "START-OF-SELECTION.",
    "  SET HANDLER zcl_local_util=>on_event FOR ALL INSTANCES.",
    "  SET HANDLER zcl_lib_util=>on_event FOR ALL INSTANCES.",
    "  SET HANDLER /abc/cl_ns_util=>on_event FOR ALL INSTANCES.",
    "  SET HANDLER zcl_filtered=>on_event FOR ALL INSTANCES.",
    "  SET HANDLER zcl_old_output=>on_event FOR ALL INSTANCES.",
  ].join("\n");
  const root = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-libs-"));
  await writeFiles(root, {
    "src/zmain.prog.abap": CALLER,
    "src/zcl_local_util.clas.abap": "",
    "src/zcl_local_util.clas.testclasses.abap": "",
    "src/skip/zcl_filtered.clas.abap": "",
    "output_converter/zcl_old_output.clas.abap": "",
    "deps/lib/src/zcl_lib_util.clas.abap": "",
    "deps/lib/src/#abc#cl_ns_util.clas.abap": "",
  });
  const configPath = path.join(root, "abap_transpile.json");
  await fs.writeFile(configPath, JSON.stringify({ ...BASE, exclude_filter: ["/skip/"], libs: [{ folder: "deps/lib" }] }), "utf8");
  const config = await loadTranspileConfig(configPath, { cwd: root });
  const libraries = loadLibraries(config);
  assert.deepEqual(libraries.classNames, ["/ABC/CL_NS_UTIL", "ZCL_LIB_UTIL"]);
  config.libraryClassNames = libraries.classNames;
  assert.deepEqual(await discoverGlobalClassNames(config), ["/ABC/CL_NS_UTIL", "ZCL_LIB_UTIL", "ZCL_LOCAL_UTIL"]);

  const summary = await convertConfiguredPrograms({ config, write: false, overrides: { mode: "partial" } });
  const unresolved = summary.programs[0].diagnostics
    .filter((item) => item.code === "GGCONV-E512")
    .map((item) => item.construct);
  assert.deepEqual(unresolved, [
    "SET HANDLER zcl_filtered=>on_event FOR ALL INSTANCES.",
    "SET HANDLER zcl_old_output=>on_event FOR ALL INSTANCES.",
  ]);
});

test("reports a lib folder that does not exist and has no url", async () => {
  const { config } = await project([{ folder: "deps/missing" }]);
  assert.throws(() => loadLibraries(config), /lib folder not found/);
});

test("clones a lib url, resolves its includes, and removes the clone afterwards", async () => {
  const repository = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-libs-repo-"));
  await writeFiles(repository, LIB_FILES);
  const git = (...args) => execFileSync("git", ["-c", "user.name=test", "-c", "user.email=test@example.invalid", ...args], { cwd: repository, stdio: "ignore" });
  git("init", "--quiet");
  git("add", ".");
  git("commit", "--quiet", "-m", "lib");

  const messages = [];
  const { config } = await project([{ url: pathToFileURL(repository).href }]);
  const libraries = loadLibraries(config, { log: (message) => messages.push(message) });
  config.libraryFolders = libraries.folders;
  const clone = path.dirname(libraries.folders[0]);
  try {
    assert.match(messages[0], /^Clone: file:/);
    assert.ok(existsSync(path.join(clone, "src", "sub", "zlib_inc.prog.abap")));
    const summary = await convertConfiguredPrograms({ config, write: false });
    assert.ok(!summary.programs[0].diagnostics.some((item) => item.code === "GGCONV-E102"));
  } finally {
    libraries.cleanup();
  }
  assert.ok(!existsSync(clone), "the clone is removed by cleanup()");

  // The same url clones to the same place, so the include paths - and with
  // them the generated class - are the same on every run.
  const again = loadLibraries(config);
  try {
    assert.deepEqual(again.folders, libraries.folders);
  } finally {
    again.cleanup();
  }
});

test("discovery ignores lib folders", async () => {
  const { config } = await project([{ folder: "deps/lib" }], { "deps/lib/src/zlib_report.prog.abap": "REPORT zlib_report.\n" });
  assert.deepEqual((await discoverPrograms(config)).map((item) => item.programName), ["ZMAIN"]);
});
