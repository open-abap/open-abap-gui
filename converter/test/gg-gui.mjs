import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import {spawn} from "node:child_process";
import {once} from "node:events";
import {createServer} from "node:net";
import {chromium} from "playwright";
import {convertProgram} from "../src/api.mjs";
import {repositoryRoot, repositoryTool} from "./repository.mjs";

const repositoryUrl = "https://github.com/larshp/gg-gui";
const validationRoot = path.join(repositoryRoot, "converter", "gg-gui-validation");
const checkoutRoot = path.join(validationRoot, "repository");
const generatedRoot = path.join(validationRoot, "generated");
const manifestsRoot = path.join(validationRoot, "manifests");
const outputRoot = path.join(validationRoot, "output");
const screenshotsRoot = path.join(validationRoot, "screenshots");
const transpileConfigPath = path.join(validationRoot, "abap_transpile.json");

function generatedClassName(programName) {
  return `ZCL_CV_${programName.replace(/^ZGG_GUI_/, "")}`.slice(0, 30);
}

function transactionCode(programName) {
  return `CV_${programName.replace(/^ZGG_GUI_/, "")}`.slice(0, 20);
}

function runCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: repositoryRoot,
      stdio: options.stdio ?? "inherit",
      env: options.env ?? process.env,
      shell: command.endsWith(".cmd"),
    });
    let stdout = "";
    if (options.stdio === "pipe") child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (signal) reject(new Error(`${command} terminated by ${signal}`));
      else if (code !== 0) reject(new Error(`${command} exited with code ${code}`));
      else resolve(stdout.trim());
    });
  });
}

async function exists(filename) {
  try { await fs.access(filename); return true; } catch { return false; }
}

async function freePort() {
  const probe = createServer();
  await new Promise((resolve) => probe.listen(0, "127.0.0.1", resolve));
  const port = probe.address().port;
  await new Promise((resolve, reject) => probe.close((error) => error ? reject(error) : resolve()));
  return port;
}

async function stopProcess(child) {
  if (!child || child.exitCode !== null || child.signalCode !== null) return;
  child.kill();
  await once(child, "close");
}

async function waitForHost(child, baseUrl) {
  const deadline = Date.now() + 15_000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) throw new Error(`ABAP HTML host exited during startup (${child.exitCode})`);
    try {
      const response = await fetch(baseUrl);
      if (response.ok) return;
    } catch {
      // The host is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error("Timed out starting the ABAP HTML host");
}

function escapeHtml(value) {
  return String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}

async function writeScreenshotIndex(results, revision) {
  const cards = results.map((result) => {
    const source = `${result.programName.toLowerCase()}.png`;
    const errorCount = result.diagnostics.filter((item) => item.severity === "error").length;
    return `<figure><a href="${source}"><img src="${source}" alt="${escapeHtml(result.programName)}"></a><figcaption><strong>${escapeHtml(result.programName)}</strong><span>${errorCount} converter error diagnostic${errorCount === 1 ? "" : "s"}</span></figcaption></figure>`;
  }).join("\n");
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>gg-gui converter screenshots</title><style>body{margin:2rem;font:16px system-ui,sans-serif;color:#1d2d3e;background:#eef3f8}h1{margin-bottom:.25rem}p{color:#52677c}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:1rem}figure{margin:0;padding:.75rem;background:#fff;border:1px solid #b7c5d3;border-radius:5px}img{display:block;width:100%;height:auto;border:1px solid #ccd6e0}figcaption{display:flex;flex-direction:column;gap:.2rem;padding-top:.5rem}strong{font-family:ui-monospace,monospace}</style></head><body><h1>gg-gui converter screenshots</h1><p>${results.length} reports from ${escapeHtml(revision)}</p><main>${cards}</main></body></html>\n`;
  await fs.writeFile(path.join(screenshotsRoot, "index.html"), html, "utf8");
}

await fs.mkdir(validationRoot, {recursive: true});

const sourceRepository = path.resolve(process.env.GG_GUI_REPOSITORY ?? checkoutRoot);
if (!process.env.GG_GUI_REPOSITORY && !await exists(path.join(sourceRepository, "src"))) {
  await runCommand("git", ["clone", "--depth", "1", repositoryUrl, sourceRepository]);
}
const sourceRoot = path.join(sourceRepository, "src");
const entries = await fs.readdir(sourceRoot);
const reportFiles = entries
  .filter((name) => /^zgg_gui_.*\.prog\.abap$/i.test(name))
  .sort((left, right) => left.localeCompare(right));

assert.ok(reportFiles.length > 0, `No gg-gui reports found in ${sourceRoot}`);
await fs.rm(generatedRoot, {recursive: true, force: true});
await fs.rm(manifestsRoot, {recursive: true, force: true});
await fs.rm(outputRoot, {recursive: true, force: true});
await fs.rm(screenshotsRoot, {recursive: true, force: true});
await fs.mkdir(generatedRoot, {recursive: true});
await fs.mkdir(manifestsRoot, {recursive: true});
await fs.mkdir(screenshotsRoot, {recursive: true});

const results = [];
const targetNames = new Set();
const resolveInclude = async (name) => {
  const includePath = path.join(sourceRoot, `${String(name).toLowerCase()}.prog.abap`);
  if (!await exists(includePath)) return undefined;
  return {filename: includePath, source: await fs.readFile(includePath, "utf8")};
};
for (const filename of reportFiles) {
  const source = await fs.readFile(path.join(sourceRoot, filename), "utf8");
  const programName = /^\s*REPORT\s+([A-Z0-9_\/]+)/im.exec(source)?.[1]?.toUpperCase();
  assert.ok(programName, `${filename} is not an executable REPORT`);
  const className = generatedClassName(programName);
  assert.ok(!targetNames.has(className), `Generated class-name collision for ${className}`);
  targetNames.add(className);
  const result = await convertProgram({
    source,
    filename,
    className,
    transactionCode: transactionCode(programName),
    description: `Converted gg-gui report ${programName}`,
    mode: "partial",
    partialStrategy: "skeleton",
    resolveInclude,
  });
  assert.ok(result.classSource, `Converter emitted no partial class for ${filename}`);
  await fs.writeFile(path.join(generatedRoot, `${result.manifest.targetClass.toLowerCase()}.clas.abap`), result.classSource, "utf8");
  await fs.writeFile(path.join(manifestsRoot, `${result.manifest.targetClass.toLowerCase()}.manifest.json`), `${JSON.stringify(result.manifest, null, 2)}\n`, "utf8");
  results.push({
    filename,
    programName,
    targetClass: result.manifest.targetClass,
    transactionCode: result.manifest.transactionCode,
    supported: result.supported,
    diagnostics: result.diagnostics,
  });
}

await fs.writeFile(transpileConfigPath, `${JSON.stringify({
  input_folder: ["src", "scaffold", "converter/gg-gui-validation/generated"],
  input_filter: [],
  exclude_filter: [],
  output_folder: "converter/gg-gui-validation/output",
  write_unit_tests: false,
  write_source_map: false,
  options: {
    setup: {filename: "../../../setup.mjs", preFunction: "setupDatabase"},
    ignoreSyntaxCheck: false,
    addFilenames: true,
    addCommonJS: true,
  },
  libs: [
    {url: "https://github.com/open-abap/open-abap-core"},
    {url: "https://github.com/open-abap/express-icf-shim"},
    {url: "https://github.com/open-abap/open-abap-bal"},
  ],
}, null, 2)}\n`, "utf8");

const revision = await runCommand("git", ["-C", sourceRepository, "rev-parse", "HEAD"], {stdio: "pipe"});
await fs.writeFile(path.join(validationRoot, "results.json"), `${JSON.stringify({repositoryUrl, revision, reports: results}, null, 2)}\n`, "utf8");
console.log(`Converted ${results.length} gg-gui reports from ${revision}`);

await runCommand(repositoryTool("abap_transpile"), [path.relative(repositoryRoot, transpileConfigPath)]);

let hostProcess;
let browser;
try {
  const port = await freePort();
  hostProcess = spawn(process.execPath, ["test/start-server.mjs"], {
    cwd: repositoryRoot,
    env: {...process.env, OPEN_ABAP_GUI_PORT: String(port), OPEN_ABAP_GUI_OUTPUT: outputRoot},
    stdio: "inherit",
  });
  const baseUrl = `http://127.0.0.1:${port}`;
  await waitForHost(hostProcess, baseUrl);

  browser = await chromium.launch({headless: true});
  const page = await browser.newPage({viewport: {width: 1440, height: 900}});
  for (const result of results) {
    const response = await page.goto(`${baseUrl}/transaction?tcode=${encodeURIComponent(result.transactionCode)}`, {waitUntil: "load"});
    assert.equal(response?.status(), 200, `Host failed for ${result.programName}`);
    await page.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
    await page.screenshot({path: path.join(screenshotsRoot, `${result.programName.toLowerCase()}.png`), fullPage: true});
  }
  await writeScreenshotIndex(results, revision);
} finally {
  await browser?.close();
  await stopProcess(hostProcess);
}

const screenshots = (await fs.readdir(screenshotsRoot)).filter((name) => name.endsWith(".png"));
assert.equal(screenshots.length, results.length, "Expected one screenshot per gg-gui report");
console.log(`Captured ${screenshots.length} report screenshots in ${screenshotsRoot}`);
