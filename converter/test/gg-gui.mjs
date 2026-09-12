import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import {spawn} from "node:child_process";
import {once} from "node:events";
import {createServer} from "node:net";
import {chromium} from "playwright";
import {convertProgram} from "../src/api.mjs";
import {loadDynproMetadata} from "../src/dynpro-metadata.mjs";
import {GG_GUI_DDIC_TYPES} from "../src/gg-gui-ddic.mjs";
import {repositoryRoot, repositoryTool} from "./repository.mjs";

const repositoryUrl = "https://github.com/larshp/gg-gui";
const validationRoot = path.join(repositoryRoot, "converter", "gg-gui-validation");
const checkoutRoot = path.join(validationRoot, "repository");
const generatedRoot = path.join(validationRoot, "generated");
const manifestsRoot = path.join(validationRoot, "manifests");
const outputRoot = path.join(validationRoot, "output");
const screenshotsRoot = path.join(validationRoot, "screenshots");
const diffRoot = path.join(validationRoot, "diffs");
const transpileConfigPath = path.join(validationRoot, "abap_transpile.json");
const screenshotViewport = {width: 1299, height: 1009};
const screenshotFixture = Object.freeze({
  date: "20250115",
  time: "120000",
  user: "GG_FIXTURE",
  host: "GG-GUI-FIXTURE",
  systemId: "GG1",
  client: "100",
  language: "E",
  timezone: "UTC",
  tempDirectory: "/fixtures/gg-gui/tmp",
  externalUrl: "https://example.invalid/gg-gui",
  sampleData: "gg-gui source and SAP screenshots from the pinned repository revision",
});
const comparisonGateDefinitions = Object.freeze([
  {id: "semanticContent", label: "Semantic content", rule: "Report-specific labels, fields, values, control roles, and fallback text are present."},
  {id: "interactiveBehavior", label: "Interactive behavior", rule: "Report-specific actions update server-owned state and preserve navigation semantics."},
  {id: "visualStructure", label: "Visual structure", rule: "Reference grouping, density, alignment, focus, and control geometry are matched."},
]);
const referenceStateAudits = Object.freeze({
  ZGG_GUI_SUBSCREENS: {
    status: "stale-reference",
    acceptance: "excluded-until-replaced",
    observedState: "SAP GUI Program Execution selection screen with ZGG_GUI_SUBSCREENS in the Program field.",
    intendedState: "Dynpro 0100 with static subscreen 0110, dynamic subscreen 0120, initial parent summary, and Back/Apply/Reset/Swap actions.",
  },
  ZGG_GUI_DIALOGS_HELP: {
    status: "stale-reference",
    acceptance: "excluded-until-replaced",
    observedState: "SAP GUI Program Execution selection screen with ZGG_GUI_DIALOGS_HELP in the Program field.",
    intendedState: "Dynpro 0100 with the GV_CHOICE field focused, F1/F4 help affordances, popup action buttons, and the initial result text.",
  },
});
const intentionalReferenceFallbacks = Object.freeze({
  ZGG_GUI_SALV_TABLE: {
    status: "intentional-fallback",
    acceptance: "allowed-when-honest",
    nativeEvidence: "Reference screen states that CL_SALV_TABLE is unavailable or nonfunctional and shows a text editor fallback with the native limitation and available actions.",
    browserContract: "Keep the read-only semantic table fallback, status text, and actions non-terminating; never claim that SALV factory/display/export succeeded.",
  },
  ZGG_GUI_GRAPHICS: {
    status: "intentional-capability-boundary",
    acceptance: "allowed-when-honest",
    nativeEvidence: "Reference screen is the Runtime capability audit for optional SAP graphics controls; installation-dependent classes are reported and construction failures are nonfatal.",
    browserContract: "Preserve the capability audit and status text, provide accessible chart/table alternatives, and label native graphics implementations unavailable when they are not actually performed.",
  },
  ZGG_GUI_ILI_DRAGDROP: {
    status: "intentional-fallback",
    acceptance: "allowed-when-honest",
    nativeEvidence: "Reference screen states that the CL_GUI_ILIDRAGNDROP_CONTROL ActiveX control is unavailable or nonfunctional and shows a text fallback with geometry/menu actions.",
    browserContract: "Keep the explicit legacy ActiveX-unavailable fallback, text area, action responses, and non-terminating Back path; do not simulate native drag/drop success.",
  },
});

function pendingComparisonGates() {
  return Object.fromEntries(comparisonGateDefinitions.map(({id, rule}) => [id, {
    status: "not-run",
    rule,
    evidence: "Pixel similarity alone cannot pass this gate.",
  }]));
}

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

function relativeHref(filename) {
  return path.relative(screenshotsRoot, filename).split(path.sep).join("/");
}

async function imageInfo(filename) {
  if (!await exists(filename)) return null;
  return {source: relativeHref(filename), dimensions: await imageDimensions(filename)};
}

async function imageDimensions(filename) {
  const data = await fs.readFile(filename);
  if (data.length < 24 || data.toString("ascii", 1, 4) !== "PNG") {
    throw new Error(`Not a PNG image: ${filename}`);
  }
  return {width: data.readUInt32BE(16), height: data.readUInt32BE(20)};
}

function dimensionsText(dimensions) {
  return dimensions ? `${dimensions.width} x ${dimensions.height}` : "not available";
}

function diagnosticMarkup(diagnostics) {
  if (diagnostics.length === 0) return "<p class=\"diagnostics-empty\">No converter diagnostics.</p>";
  const items = diagnostics.map((item) => {
    const location = item.start?.line
      ? `${item.filename || "source"}:${item.start.line}:${item.start.column || 1}`
      : item.filename || "source";
    return `<li><div><span class=\"diagnostic-code\">${escapeHtml(item.code || "diagnostic")}</span><span class=\"diagnostic-severity diagnostic-severity--${escapeHtml(item.severity || "info")}\">${escapeHtml(item.severity || "info")}</span><span class=\"diagnostic-location\">${escapeHtml(location)}</span></div><p>${escapeHtml(item.message || "")}</p>${item.construct ? `<code>${escapeHtml(item.construct)}</code>` : ""}</li>`;
  }).join("\n");
  return `<details class=\"diagnostics\"><summary>${diagnostics.length} diagnostic${diagnostics.length === 1 ? "" : "s"}</summary><ol>${items}</ol></details>`;
}

async function writeScreenshotIndex(results, revision, referenceRoot) {
  const cards = (await Promise.all(results.map(async (result) => {
    const filename = `${result.programName.toLowerCase()}.png`;
    const generated = await imageInfo(path.join(screenshotsRoot, filename));
    const reference = await imageInfo(path.join(referenceRoot, filename));
    const diff = await imageInfo(path.join(diffRoot, "images", filename));
    const errors = result.diagnostics.filter((item) => item.severity === "error").length;
    const warnings = result.diagnostics.filter((item) => item.severity === "warning").length;
    const status = result.supported ? "supported" : "partial";
    const statusLabel = result.supported ? "supported conversion" : "partial conversion";
    const diagnosticSummary = `${errors} error${errors === 1 ? "" : "s"}, ${warnings} warning${warnings === 1 ? "" : "s"}`;
    const gates = result.comparisonGates || pendingComparisonGates();
    const referenceAudit = referenceStateAudits[result.programName];
    const fallbackAudit = intentionalReferenceFallbacks[result.programName];
    const imageMarkup = ({info, alt, missingLabel}) => info
      ? `<a href="${escapeHtml(info.source)}"><img src="${escapeHtml(info.source)}" alt="${escapeHtml(alt)}" width="${info.dimensions.width}" height="${info.dimensions.height}" loading="lazy"></a>`
      : `<div class="missing">${escapeHtml(missingLabel)}</div>`;
    const gateMarkup = comparisonGateDefinitions.map(({id, label}) => {
      const gate = gates[id] || {status: "not-run", evidence: "Pixel similarity alone cannot pass this gate."};
      return `<li class="gate gate--${escapeHtml(gate.status)}"><strong>${escapeHtml(label)}:</strong> ${escapeHtml(gate.status)}<span>${escapeHtml(gate.evidence || gate.rule || "")}</span></li>`;
    }).join("");
    return `<article class="comparison-card comparison-card--${status}" id="${escapeHtml(result.programName.toLowerCase())}" data-program="${escapeHtml(result.programName)}" data-conversion-status="${status}" data-comparison-accepted="false">
  <header><h2>${escapeHtml(result.programName)}</h2><span class="status">${statusLabel}</span><span class="comparison-status">not accepted</span><span class="diagnostic-count">${diagnosticSummary}</span></header>
  <div class="panels">
    <figure><figcaption>Generated browser <span>${dimensionsText(generated?.dimensions)}</span></figcaption>${imageMarkup({info: generated, alt: `${result.programName} generated browser screen`, missingLabel: "Generated image not present"})}</figure>
    <figure><figcaption>SAP GUI reference <span>${dimensionsText(reference?.dimensions)}</span></figcaption>${imageMarkup({info: reference, alt: `${result.programName} SAP GUI reference`, missingLabel: "Reference image not present"})}</figure>
    <figure><figcaption>Optional pixel diff <span>${dimensionsText(diff?.dimensions)}</span></figcaption>${imageMarkup({info: diff, alt: `${result.programName} pixel difference`, missingLabel: "No diff image generated"})}</figure>
  </div>
  <p class="metadata"><strong>Reference dimensions:</strong> ${dimensionsText(reference?.dimensions)}<br><strong>Target:</strong> ${escapeHtml(result.targetClass)} - <strong>Transaction:</strong> ${escapeHtml(result.transactionCode)}</p>
  ${referenceAudit ? `<section class="reference-audit" data-reference-audit="${escapeHtml(referenceAudit.status)}"><h3>Reference audit: ${escapeHtml(referenceAudit.acceptance)}</h3><p><strong>Observed:</strong> ${escapeHtml(referenceAudit.observedState)}<br><strong>Intended:</strong> ${escapeHtml(referenceAudit.intendedState)}</p></section>` : ""}
  ${fallbackAudit ? `<section class="fallback-audit" data-fallback-audit="${escapeHtml(fallbackAudit.status)}"><h3>Intentional capability boundary: ${escapeHtml(fallbackAudit.acceptance)}</h3><p><strong>Native evidence:</strong> ${escapeHtml(fallbackAudit.nativeEvidence)}<br><strong>Browser contract:</strong> ${escapeHtml(fallbackAudit.browserContract)}</p></section>` : ""}
  <section class="gate-section" aria-label="Comparison gates"><h3>Comparison gates</h3><ul>${gateMarkup}</ul><p>Pixel similarity is visual evidence only; acceptance requires all three gates to pass.</p></section>
  ${diagnosticMarkup(result.diagnostics)}
</article>`;
  }))).join("\n");
  const html = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>gg-gui conversion comparison</title>
    <style>
      :root { color-scheme: light; font: 16px system-ui, sans-serif; color: #1d2d3e; background: #eef3f8; }
      body { margin: 2rem; }
      h1 { margin: 0 0 .25rem; }
      .intro { margin: 0 0 1.5rem; color: #52677c; }
      main { display: grid; gap: 1rem; }
      .comparison-card { padding: 1rem; border: 1px solid #b7c5d3; border-radius: 6px; background: #fff; }
      .comparison-card > header { display: flex; align-items: center; flex-wrap: wrap; gap: .65rem; margin-bottom: .8rem; }
      h2 { margin: 0 auto 0 0; font: 700 1rem ui-monospace, monospace; }
      .status, .diagnostic-count { padding: .3rem .6rem; border-radius: 999px; background: #dce8f3; font-size: .9rem; font-weight: 650; }
      .comparison-card--supported .status { color: #155c25; background: #d8f0dc; }
      .comparison-card--partial .status { color: #704900; background: #ffe8b8; }
      .comparison-status { padding: .3rem .6rem; border-radius: 999px; color: #8b2020; background: #f5d9d9; font-size: .9rem; font-weight: 650; }
      .panels { display: grid; grid-template-columns: repeat(3, minmax(220px, 1fr)); gap: 1rem; align-items: start; }
      figure { min-width: 0; margin: 0; }
      figcaption { display: flex; justify-content: space-between; gap: .5rem; margin-bottom: .4rem; font-weight: 650; }
      figcaption span { color: #52677c; font: .85rem ui-monospace, monospace; white-space: nowrap; }
      a { display: block; }
      img { display: block; width: 100%; height: auto; border: 1px solid #ccd6e0; background: #fff; }
      .missing { display: grid; min-height: 10rem; place-items: center; border: 1px dashed #aebfd2; color: #6d7f90; background: #f6f8fa; text-align: center; }
      .metadata { margin: .8rem 0 0; color: #52677c; font-size: .9rem; }
      .reference-audit { margin-top: .8rem; border: 1px solid #e0b45c; border-radius: 4px; padding: .6rem .75rem; color: #704900; background: #fff7df; }
      .reference-audit h3 { margin: 0 0 .35rem; font-size: .9rem; }
      .reference-audit p { margin: 0; font-size: .85rem; }
      .fallback-audit { margin-top: .8rem; border: 1px solid #8eb6d4; border-radius: 4px; padding: .6rem .75rem; color: #294761; background: #edf7ff; }
      .fallback-audit h3 { margin: 0 0 .35rem; font-size: .9rem; }
      .fallback-audit p { margin: 0; font-size: .85rem; }
      .gate-section { margin-top: .8rem; border-top: 1px solid #d5e0ea; padding-top: .6rem; }
      .gate-section h3 { margin: 0 0 .4rem; font-size: .95rem; }
      .gate-section ul { display: grid; gap: .3rem; margin: 0; padding: 0; list-style: none; }
      .gate { display: flex; flex-wrap: wrap; gap: .4rem; align-items: baseline; color: #8b2020; font-size: .9rem; }
      .gate span { color: #52677c; }
      .gate-section > p { margin: .5rem 0 0; color: #52677c; font-size: .85rem; }
      .diagnostics { margin-top: .8rem; border-top: 1px solid #d5e0ea; padding-top: .6rem; }
      .diagnostics summary { cursor: pointer; color: #294761; font-weight: 650; }
      .diagnostics ol { margin: .6rem 0 0; padding-left: 1.5rem; }
      .diagnostics li { margin: 0 0 .65rem; }
      .diagnostics li > div { display: flex; flex-wrap: wrap; gap: .45rem; align-items: baseline; }
      .diagnostics p { margin: .15rem 0; }
      .diagnostics code { display: block; overflow-wrap: anywhere; color: #52677c; white-space: pre-wrap; }
      .diagnostic-code { font: 700 .85rem ui-monospace, monospace; }
      .diagnostic-severity { font-size: .8rem; text-transform: uppercase; }
      .diagnostic-severity--error { color: #9a1f1f; }
      .diagnostic-severity--warning { color: #8a5a00; }
      .diagnostic-location { color: #6d7f90; font: .8rem ui-monospace, monospace; }
      .diagnostics-empty { color: #52677c; }
      @media (max-width: 900px) { body { margin: 1rem; } .panels { grid-template-columns: 1fr; } }
    </style>
  </head>
  <body>
    <h1>gg-gui conversion comparison</h1>
    <p class="intro">${results.length} reports from ${escapeHtml(revision)}. Browser capture viewport: ${screenshotViewport.width} x ${screenshotViewport.height}. Deterministic fixture: ${screenshotFixture.date} ${screenshotFixture.time} UTC, user ${escapeHtml(screenshotFixture.user)}, path ${escapeHtml(screenshotFixture.tempDirectory)}, URL ${escapeHtml(screenshotFixture.externalUrl)}. Each card includes the generated browser screen, the SAP GUI reference, and an optional diff image. Comparison acceptance requires semantic-content, interactive-behavior, and visual-structure gates; pixel similarity is evidence only. See the <a href="../reference-audit.json">reference audit</a> and <a href="../fallback-audit.json">fallback audit</a>.</p>
    <main>
${cards}
    </main>
  </body>
</html>
`;
  await fs.writeFile(path.join(screenshotsRoot, "index.html"), html, "utf8");
}

async function writeReferenceAudit(revision, referenceRoot) {
  const audits = await Promise.all(Object.entries(referenceStateAudits).map(async ([programName, audit]) => {
    const filename = `${programName.toLowerCase()}.png`;
    const referencePath = path.join(referenceRoot, filename);
    const data = await fs.readFile(referencePath);
    return [programName, {
      ...audit,
      filename,
      dimensions: await imageDimensions(referencePath),
      sha256: createHash("sha256").update(data).digest("hex"),
    }];
  }));
  await fs.writeFile(path.join(validationRoot, "reference-audit.json"), `${JSON.stringify({
    repositoryUrl,
    revision,
    referenceDirectory: path.relative(validationRoot, referenceRoot).split(path.sep).join("/"),
    audits: Object.fromEntries(audits),
  }, null, 2)}\n`, "utf8");
}

async function writeFallbackAudit(revision, referenceRoot) {
  const fallbacks = await Promise.all(Object.entries(intentionalReferenceFallbacks).map(async ([programName, fallback]) => {
    const filename = `${programName.toLowerCase()}.png`;
    const referencePath = path.join(referenceRoot, filename);
    const data = await fs.readFile(referencePath);
    return [programName, {
      ...fallback,
      filename,
      dimensions: await imageDimensions(referencePath),
      sha256: createHash("sha256").update(data).digest("hex"),
    }];
  }));
  await fs.writeFile(path.join(validationRoot, "fallback-audit.json"), `${JSON.stringify({
    repositoryUrl,
    revision,
    referenceDirectory: path.relative(validationRoot, referenceRoot).split(path.sep).join("/"),
    fallbacks: Object.fromEntries(fallbacks),
  }, null, 2)}\n`, "utf8");
}

await fs.mkdir(validationRoot, {recursive: true});

const sourceRepository = path.resolve(process.env.GG_GUI_REPOSITORY ?? checkoutRoot);
if (!process.env.GG_GUI_REPOSITORY && !await exists(path.join(sourceRepository, "src"))) {
  await runCommand("git", ["clone", "--depth", "1", repositoryUrl, sourceRepository]);
}
const referenceRoot = path.join(sourceRepository, "sap-screenshots");
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
  const reportPath = path.join(sourceRoot, filename);
  const source = await fs.readFile(reportPath, "utf8");
  const programName = /^\s*REPORT\s+([A-Z0-9_\/]+)/im.exec(source)?.[1]?.toUpperCase();
  assert.ok(programName, `${filename} is not an executable REPORT`);
  const screenMetadata = await loadDynproMetadata({filename: reportPath});
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
    screenMetadata,
    ddicTypes: GG_GUI_DDIC_TYPES,
  });
  assert.ok(result.classSource, `Converter emitted no partial class for ${filename}`);
  await fs.writeFile(path.join(generatedRoot, `${result.manifest.targetClass.toLowerCase()}.clas.abap`), result.classSource, "utf8");
  for (const helper of result.helperSources ?? []) {
    await fs.writeFile(path.join(generatedRoot, `${helper.className.toLowerCase()}.clas.abap`), helper.source, "utf8");
  }
  await fs.writeFile(path.join(manifestsRoot, `${result.manifest.targetClass.toLowerCase()}.manifest.json`), `${JSON.stringify(result.manifest, null, 2)}\n`, "utf8");
  results.push({
    filename,
    programName,
    targetClass: result.manifest.targetClass,
    transactionCode: result.manifest.transactionCode,
    supported: result.supported,
    diagnostics: result.diagnostics,
    comparisonAccepted: false,
    comparisonGates: pendingComparisonGates(),
    fallbackAudit: intentionalReferenceFallbacks[programName] || null,
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
await writeReferenceAudit(revision, referenceRoot);
await writeFallbackAudit(revision, referenceRoot);
await fs.writeFile(path.join(validationRoot, "results.json"), `${JSON.stringify({repositoryUrl, revision, screenshotViewport, screenshotFixture, comparisonGateDefinitions, reports: results}, null, 2)}\n`, "utf8");
console.log(`Converted ${results.length} gg-gui reports from ${revision}`);

await runCommand(repositoryTool("abap_transpile"), [path.relative(repositoryRoot, transpileConfigPath)]);

let hostProcess;
let browser;
try {
  const port = await freePort();
  hostProcess = spawn(process.execPath, ["test/start-server.mjs"], {
    cwd: repositoryRoot,
    env: {
      ...process.env,
      TZ: screenshotFixture.timezone,
      LANG: "en-US",
      LC_ALL: "C",
      OPEN_ABAP_GUI_PORT: String(port),
      OPEN_ABAP_GUI_OUTPUT: outputRoot,
      OPEN_ABAP_GUI_FIXED_DATE: screenshotFixture.date,
      OPEN_ABAP_GUI_FIXED_TIME: screenshotFixture.time,
      OPEN_ABAP_GUI_FIXED_USER: screenshotFixture.user,
      OPEN_ABAP_GUI_FIXED_HOST: screenshotFixture.host,
      OPEN_ABAP_GUI_FIXED_SYSID: screenshotFixture.systemId,
      OPEN_ABAP_GUI_FIXED_MANDT: screenshotFixture.client,
      OPEN_ABAP_GUI_FIXED_LANG: screenshotFixture.language,
      OPEN_ABAP_GUI_FIXED_TIMEZONE: screenshotFixture.timezone,
      OPEN_ABAP_GUI_FIXED_TEMP_DIR: screenshotFixture.tempDirectory,
      OPEN_ABAP_GUI_FIXED_URL: screenshotFixture.externalUrl,
    },
    stdio: "inherit",
  });
  const baseUrl = `http://127.0.0.1:${port}`;
  await waitForHost(hostProcess, baseUrl);

  browser = await chromium.launch({headless: true});
  const page = await browser.newPage({viewport: screenshotViewport, locale: "en-US", timezoneId: screenshotFixture.timezone});
  for (const result of results) {
    const response = await page.goto(`${baseUrl}/transaction?tcode=${encodeURIComponent(result.transactionCode)}`, {waitUntil: "load"});
    assert.equal(response?.status(), 200, `Host failed for ${result.programName}`);
    await page.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
    await page.screenshot({path: path.join(screenshotsRoot, `${result.programName.toLowerCase()}.png`), fullPage: true});
  }
  await writeScreenshotIndex(results, revision, referenceRoot);
  await runCommand(process.execPath, [
    path.join(repositoryRoot, "test", "generate-screenshot-diffs.mjs"),
    referenceRoot,
    screenshotsRoot,
    diffRoot,
  ]);
  await writeScreenshotIndex(results, revision, referenceRoot);
} finally {
  await browser?.close();
  await stopProcess(hostProcess);
}

const screenshots = (await fs.readdir(screenshotsRoot)).filter((name) => name.endsWith(".png"));
assert.equal(screenshots.length, results.length, "Expected one screenshot per gg-gui report");
console.log(`Captured ${screenshots.length} report screenshots in ${screenshotsRoot}`);
