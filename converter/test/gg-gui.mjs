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
const screenshotEnvironment = Object.freeze({
  viewport: screenshotViewport,
  locale: "en-US",
  timezone: screenshotFixture.timezone,
  fonts: ["system-ui", "Segoe UI", "Tahoma", "Arial", "ui-monospace", "Consolas"],
  animations: "disabled-by-capture-contract",
});
const genericPartialHeadings = Object.freeze([
  "partial conversion",
  "generic conversion diagnostic",
  "no application content",
]);
const comparisonGateDefinitions = Object.freeze([
  {id: "semanticContent", label: "Semantic content", rule: "Report-specific labels, fields, values, control roles, and fallback text are present."},
  {id: "interactiveBehavior", label: "Interactive behavior", rule: "Report-specific actions update program-owned application state, or are explicitly verified fresh-session idempotent lifecycle actions, and preserve navigation semantics."},
  {id: "visualStructure", label: "Visual structure", rule: "Reference grouping, density, alignment, focus, and control geometry are matched."},
]);
const referenceStateAudits = Object.freeze({
  ZGG_GUI_SUBSCREENS: {
    status: "stale-reference-confirmed",
    acceptance: "excluded-from-pixel-acceptance",
    observedState: "SAP GUI Program Execution selection screen with ZGG_GUI_SUBSCREENS in the Program field.",
    intendedState: "Dynpro 0100 with static subscreen 0110, dynamic subscreen 0120, initial parent summary, and Back/Apply/Reset/Swap actions.",
    verification: "The live transaction audit reaches DYNPRO 0100 and verifies static/dynamic subscreen identity, state retention, actions, and Back navigation; the pinned screenshot remains a launcher capture.",
  },
  ZGG_GUI_DIALOGS_HELP: {
    status: "stale-reference-confirmed",
    acceptance: "excluded-from-pixel-acceptance",
    observedState: "SAP GUI Program Execution selection screen with ZGG_GUI_DIALOGS_HELP in the Program field.",
    intendedState: "Dynpro 0100 with the GV_CHOICE field focused, F1/F4 help affordances, popup action buttons, and the initial result text.",
    verification: "The live transaction audit reaches DYNPRO 0100 and verifies value help, F1 help, dialog, confirmation, and navigation behavior; the pinned screenshot remains a launcher capture.",
  },
});
const intentionalReferenceFallbacks = Object.freeze({
  ZGG_GUI_ALV_DYNAMIC: {
    status: "intentional-capability-boundary",
    acceptance: "allowed-when-honest",
    nativeEvidence: "Reference source uses generic FIELD-SYMBOLS, dynamic ASSIGN COMPONENT, and FREE operations that remain explicit E515/E516 converter diagnostics rather than being guessed into typed code.",
    browserContract: "Preserve the typed visible ALV rows, columns, style/description/refresh/reset actions, and explicit partial-conversion diagnostics; do not claim arbitrary dynamic field-symbol reflection is fully portable.",
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
const idempotentReferenceActions = Object.freeze({
  ZGG_GUI_ABAP_BROWSER: Object.freeze({
    HTML_CONTAINER: "Fresh-session HTML_CONTAINER reapplies the same document to the same custom container; dispatch and the unchanged report-owned HTML/status are verified.",
  }),
  ZGG_GUI_DIALOG_CONTAINER: Object.freeze({
    RECREATE: "Fresh-session RECREATE rebuilds the same dialog geometry and text; the lifecycle dispatch is verified while the resulting report-owned surface is intentionally identical.",
  }),
  ZGG_GUI_DOCKING_CONTAINER: Object.freeze({
    RECREATE: "Fresh-session RECREATE rebuilds the same docking side, extension, and text; the lifecycle dispatch is verified while the resulting report-owned surface is intentionally identical.",
  }),
  ZGG_GUI_SEL_TABS: Object.freeze({
    "TAB:G_TABID|TAB1": "Fresh-session TAB1 selects the already-active Identity tab; the server dispatch is verified and the unchanged selection surface is intentional.",
  }),
  ZGG_GUI_SUBSCREENS: Object.freeze({
    RESET: "Fresh-session RESET restores the declared initial subscreen values; the server dispatch is verified and the unchanged initial surface is intentional.",
  }),
  ZGG_GUI_TABSTRIP: Object.freeze({
    "TAB:GV_TAB1_TITLE|TAB1": "Fresh-session TAB1 selects the already-active Identity tab; the server dispatch is verified and the unchanged selection surface is intentional.",
  }),
  ZGG_GUI_TREE_MODELS: Object.freeze({
    SIMPLE: "Fresh-session SIMPLE selects the report's declared default model; the server dispatch is verified and the unchanged initial model surface is intentional.",
    RESET: "Fresh-session RESET restores the declared default model; the server dispatch is verified and the unchanged initial model surface is intentional.",
  }),
});
const knownFailingReports = Object.freeze([]);

function isKnownFailingReport(programName) {
  return knownFailingReports.includes(programName.replace(/^ZGG_GUI_/, ""));
}

function idempotentActionReason(programName, ucomm) {
  return idempotentReferenceActions[programName]?.[ucomm] || "";
}

function pendingComparisonGates() {
  return Object.fromEntries(comparisonGateDefinitions.map(({id, rule}) => [id, {
    status: "not-run",
    rule,
    evidence: "Pixel similarity alone cannot pass this gate.",
  }]));
}

function pendingSmokeTest() {
  return {
    status: "not-run",
    evidence: "The report route must render a report-specific first meaningful screen.",
  };
}

function hasGenericPartialHeading(headings) {
  return headings.some((heading) => genericPartialHeadings.some((text) => heading.toLowerCase().includes(text)));
}

function generatedClassName(programName) {
  return `ZCL_CV_${programName.replace(/^ZGG_GUI_/, "")}`.slice(0, 30);
}

function transactionCode(programName) {
  return `CV_${programName.replace(/^ZGG_GUI_/, "")}`.slice(0, 20);
}

function visualContractFor(programName, screenMetadata) {
  const screen = screenMetadata?.screens?.find((item) => item.number === screenMetadata.initialScreen)
    ?? screenMetadata?.screens?.[0];
  const renderedElementKinds = new Set(["output", "input", "input-output", "checkbox", "radio", "dropdown", "pushbutton"]);
  const namedElements = (screen?.elements ?? [])
    .filter((element) => element.name && renderedElementKinds.has(String(element.kind ?? "").toLowerCase()))
    .map((element, index) => ({element, index}))
    .sort((left, right) => Number(left.element.line ?? left.element.position?.line ?? 999999) - Number(right.element.line ?? right.element.position?.line ?? 999999)
      || Number(left.element.column ?? left.element.position?.column ?? 999999) - Number(right.element.column ?? right.element.position?.column ?? 999999)
      || left.index - right.index)
    .map(({element}) => element)
    .map((element) => ({
      name: String(element.name).toUpperCase(),
      kind: String(element.kind ?? "element").toLowerCase(),
      visible: element.invisible !== true,
      container: String(element.attributes?.contName ?? "").toUpperCase(),
      ucomm: element.ucomm ? String(element.ucomm).toUpperCase() : "",
    }));
  const containers = (screen?.containers ?? [])
    .filter((container) => container.name)
    .map((container) => ({
      name: String(container.name).toUpperCase(),
      kind: String(container.type ?? container.kind ?? "container").toUpperCase(),
    }));
  return {
    programName,
    screenNumber: screen?.number,
    title: String(screen?.title ?? screen?.description ?? ""),
    geometry: screen?.geometry ?? {},
    cursor: screen?.cursor ? String(screen.cursor).toUpperCase() : "",
    elements: namedElements,
    containers,
  };
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

async function newScreenshotPage(browser) {
  const page = await browser.newPage({
    viewport: screenshotEnvironment.viewport,
    locale: screenshotEnvironment.locale,
    timezoneId: screenshotEnvironment.timezone,
  });
  await page.emulateMedia({reducedMotion: "reduce"});
  await page.addInitScript(() => {
    document.addEventListener("DOMContentLoaded", () => {
      const style = document.createElement("style");
      style.textContent = "*, *::before, *::after { animation: none !important; transition: none !important; }";
      document.head.append(style);
    }, {once: true});
  });
  return page;
}

async function waitForDeterministicFonts(page) {
  await page.evaluate(() => document.fonts?.ready);
}

async function programOwnedFingerprint(page) {
  return page.locator("[data-page-kind]").evaluate((pageRoot) => {
    const application = pageRoot.querySelector(".gg-page") || pageRoot;
    const copy = application.cloneNode(true);
    copy.querySelectorAll("script, input[name=session_id], input[name=page_id]").forEach((node) => node.remove());
    copy.querySelectorAll("[data-session-id], [data-page-id]").forEach((node) => {
      node.removeAttribute("data-session-id");
      node.removeAttribute("data-page-id");
    });
    return copy.innerHTML;
  });
}

async function inventoryReferenceActions(page) {
  const submitControls = await page.locator(".wb-runtime-content button[type=submit], .wb-runtime-content input[type=submit]").evaluateAll((elements) => {
    const isVisible = (element) => {
      if (element.disabled || element.hidden) return false;
      for (let current = element; current; current = current.parentElement) {
        if (current.hidden || current.matches("details:not([open])")) return false;
        const style = getComputedStyle(current);
        if (style.display === "none" || style.visibility === "hidden") return false;
      }
      const rect = element.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    };
    return elements.map((element, index) => ({
    index,
    name: element.getAttribute("name") || "",
    value: element.getAttribute("value") || "",
    label: (element.getAttribute("aria-label") || element.textContent || element.getAttribute("value") || "").trim().replace(/\s+/g, " "),
    disabled: element.disabled,
    visible: isVisible(element),
  })).filter((item) => item.visible);
  });
  const selectionChanges = await page.locator(".wb-runtime-content [data-selection-ucomm]").evaluateAll((elements) => {
    const isVisible = (element) => {
      if (element.disabled || element.hidden) return false;
      for (let current = element; current; current = current.parentElement) {
        if (current.hidden || current.matches("details:not([open])")) return false;
        const style = getComputedStyle(current);
        if (style.display === "none" || style.visibility === "hidden") return false;
      }
      const rect = element.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    };
    return elements.map((element, index) => ({
    index,
    name: element.getAttribute("name") || "",
    ucomm: element.getAttribute("data-selection-ucomm") || "",
    type: element.getAttribute("type") || element.tagName.toLowerCase(),
    label: (element.getAttribute("aria-label") || element.getAttribute("name") || "selection change").trim(),
    checked: Boolean(element.checked),
    optionCount: element.tagName.toLowerCase() === "select" ? element.options.length : 0,
    disabled: element.disabled,
    visible: isVisible(element),
  })).filter((item) => item.visible);
  });
  return {submitControls, selectionChanges};
}

async function auditVisualStructure(page, result) {
  const audit = await page.locator("[data-page-kind]").evaluate((runtime, contract) => {
    const pageRoot = runtime.querySelector(".gg-page");
    const kind = String(runtime.getAttribute("data-page-kind") || "").toUpperCase();
    const visible = (element) => {
      if (!element || element.hidden) return false;
      for (let current = element; current; current = current.parentElement) {
        if (current.hidden || current.classList.contains("hidden") || current.matches("details:not([open])")) return false;
        const style = getComputedStyle(current);
        if (style.display === "none" || style.visibility === "hidden") return false;
      }
      const rect = element.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    };
    const rect = (element) => {
      const value = element?.getBoundingClientRect();
      return value ? {width: Math.round(value.width), height: Math.round(value.height)} : {width: 0, height: 0};
    };
    const suppressed = (element) => {
      for (let current = element; current; current = current.parentElement) {
        if (current.hidden || current.classList.contains("hidden") || current.matches("details:not([open])")) return true;
        const style = getComputedStyle(current);
        if (style.display === "none" || style.visibility === "hidden") return true;
      }
      return false;
    };
    const checks = [];
    const check = (id, pass, evidence) => checks.push({id, pass: Boolean(pass), evidence});
    const requiredByKind = {
      SELECTION: [".gg-page.gg-page--selection", ".gg-message-region", ".gg-work-area", ".gg-selection"],
      LIST: [".gg-page.gg-page--list", ".gg-message-region", ".gg-work-area", ".gg-list"],
      DYNPRO: [".gg-page.gg-page--dynpro", ".gg-message-region", ".gg-work-area", ".gg-dynpro"],
    };
    const hierarchy = requiredByKind[kind] ?? [".gg-page", ".gg-message-region"];
    const hasSelector = (selector) => Boolean(pageRoot?.matches(selector) || pageRoot?.querySelector(selector));
    check("hierarchy", hierarchy.every(hasSelector), `${kind} page exposes its status/message/work-area hierarchy`);
    check("page-geometry", Boolean(pageRoot && rect(pageRoot).width > 0 && rect(pageRoot).height > 0), `Page region is ${rect(pageRoot).width} x ${rect(pageRoot).height}`);
    const workArea = pageRoot?.querySelector(".gg-work-area");
    check("work-area-geometry", Boolean(workArea && rect(workArea).width > 0 && rect(workArea).height > 0), `Work area is ${rect(workArea).width} x ${rect(workArea).height}`);

    const namedNodes = [...(pageRoot?.querySelectorAll("[data-abap-name],[data-custom-control],input[name],select[name],textarea[name],output[id],button[name]") ?? [])]
      .filter((node) => !["session_id", "page_id", "action", "gg_action"].includes(node.getAttribute("name")));
    const nodeNames = (node) => [
      node.getAttribute("data-abap-name"),
      node.getAttribute("data-custom-control"),
      node.getAttribute("name"),
      node.getAttribute("id"),
    ].filter(Boolean).map((value) => String(value).toUpperCase());
    const findNode = (name) => namedNodes.find((node) => nodeNames(node).some((value) => value === name || value.endsWith(`-${name}`) || value.includes(`-${name}-`)));
    const findElement = (element) => findNode(element.name)
      || (element.ucomm && [...(pageRoot?.querySelectorAll('button[name="gg_ucomm"]') ?? [])]
        .find((button) => String(button.getAttribute("value") || "").toUpperCase() === element.ucomm));
    const expectedElements = (contract?.elements ?? []).filter((element) => {
      if (kind === "SELECTION") return false;
      const owner = (contract?.containers ?? []).find((container) => container.name === element.container);
      return !["TABLE_CTRL", "STRIP_CTRL"].includes(owner?.kind);
    });
    const missingElements = expectedElements.filter((element) => !findElement(element)).map((element) => element.name);
    check("control-types", missingElements.length === 0, missingElements.length === 0
      ? `${expectedElements.length} metadata field/control name(s) are represented by typed HTML controls`
      : `Missing typed representation for ${missingElements.join(", ")}`);
    const customHosts = [...(pageRoot?.querySelectorAll('[data-custom-control],[data-control-kind="CUSTOM_CONTAINER"]') ?? [])];
    const customHostFor = (container) => customHosts.find((node) => nodeNames(node).some((value) => value === container.name || value.endsWith(`-${container.name}`))
      || String(node.textContent || "").toUpperCase().includes(`NAME=${container.name};`));
    const missingContainers = (contract?.containers ?? [])
      .filter((container) => container.kind === "CUST_CTRL")
      .filter(() => kind === "DYNPRO")
      .filter((container) => !customHostFor(container))
      .map((container) => container.name);
    check("custom-controls", missingContainers.length === 0, missingContainers.length === 0
      ? `${(contract?.containers ?? []).filter((container) => container.kind === "CUST_CTRL").length} custom-control host(s) represented`
      : `Missing custom-control host(s): ${missingContainers.join(", ")}`);
    const orderedPositions = expectedElements.map((element) => namedNodes.indexOf(findElement(element))).filter((index) => index >= 0);
    check("field-order", orderedPositions.every((position, index) => index === 0 || position >= orderedPositions[index - 1]), "Metadata field/control order is preserved in document order");

    const hiddenFocusables = [...(pageRoot?.querySelectorAll("input:not([type=hidden]),select,textarea,button,a,[tabindex]") ?? [])]
      .filter((element) => !element.disabled && !["action", "gg_action"].includes(element.getAttribute("name")) && !visible(element) && !suppressed(element));
    check("visible-state", hiddenFocusables.length === 0, hiddenFocusables.length === 0
      ? "Runtime-hidden controls are excluded from the visible and focusable surface"
      : `Hidden focusable controls remain in the active surface: ${hiddenFocusables.slice(0, 8).map((element) => element.getAttribute("name") || element.tagName.toLowerCase()).join(", ")}`);
    const interactive = [...(pageRoot?.querySelectorAll("input:not([type=hidden]),select,textarea,button,a,[role=button]") ?? [])];
    const zeroGeometry = interactive.filter((element) => !element.hidden && !["action", "gg_action"].includes(element.getAttribute("name")) && !suppressed(element) && !visible(element)).map((element) => element.getAttribute("name") || element.getAttribute("aria-label") || element.tagName.toLowerCase());
    check("interactive-geometry", zeroGeometry.length === 0, zeroGeometry.length === 0
      ? `${interactive.length} interactive control(s) have visible geometry`
      : `Interactive controls without visible geometry: ${zeroGeometry.slice(0, 8).join(", ")}`);

    const densityRows = [...(pageRoot?.querySelectorAll(".gg-selection-line,.gg-list-line,.gg-alv tr,.gg-salv-table tr,.gg-salv-tree tr") ?? [])].filter(visible);
    const oversizedRows = densityRows.filter((row) => rect(row).height > 128).length;
    check("density", oversizedRows === 0, `${densityRows.length} rendered row/line region(s) stay within dense web-native bounds`);
    const numericControls = [...(pageRoot?.querySelectorAll(".gg-type-number") ?? [])].filter(visible);
    const numericMisaligned = numericControls.filter((control) => getComputedStyle(control).textAlign !== "right").length;
    check("alignment", numericMisaligned === 0, `${numericControls.length} numeric control(s) use right alignment`);

    const focusField = pageRoot?.querySelector(".gg-dynpro")?.getAttribute("data-cursor-field") || "";
    const autofocus = [...(pageRoot?.querySelectorAll("[autofocus]") ?? [])].filter(visible);
    const sourceInputs = kind === "SELECTION"
      ? [...(pageRoot?.querySelectorAll("input:not([type=hidden]),select,textarea") ?? [])]
      : expectedElements.filter((element) => element.visible !== false && ["input", "input-output"].includes(element.kind));
    const focusApplicable = sourceInputs.length > 0 && (kind === "SELECTION" || Boolean(contract?.cursor));
    const focusPass = !focusApplicable || autofocus.length > 0 || Boolean(focusField && findNode(focusField));
    check("initial-focus", focusPass, focusPass
      ? (focusApplicable ? "Initial field focus is declared by autofocus or dynpro cursor metadata" : "No source field requires an initial focus target")
      : "A source field exists without an initial focus target");
    const typedSurfaceCount = pageRoot?.querySelectorAll("[data-control-kind],[data-table-control],[data-custom-control],input,select,textarea,button").length ?? 0;
    check("typed-surface", typedSurfaceCount > 0, `${typedSurfaceCount} typed/native-boundary HTML surface node(s) are present`);
    return {
      kind,
      geometry: {page: rect(pageRoot), workArea: rect(workArea)},
      checks,
    };
  }, result.visualContract);
  const failed = audit.checks.filter((check) => !check.pass);
  return {
    status: failed.length === 0 ? "passed" : "failed",
    checks: audit.checks,
    evidence: failed.length === 0
      ? `Reference-structure audit passed for ${audit.kind}: hierarchy, typed controls, field order, grouping/density, alignment, visible state, geometry, and initial focus are represented in accessible HTML.`
      : failed.map((check) => `${check.id}: ${check.evidence}`).join("; "),
  };
}

async function postDispatch(page, request) {
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const response = await page.context().request.post(new URL("/dispatch", page.url()).href, {
    headers: {"content-type": "application/json"},
    data: {session_id: sessionId, page_id: pageId, ...request},
  });
  return {status: response.status(), body: await response.text()};
}

async function runReferenceInteractionAudit(browser, baseUrl, results) {
  const actionPage = await newScreenshotPage(browser);
  const negativePage = await newScreenshotPage(browser);
  actionPage.on("dialog", async (dialog) => dialog.accept());
  try {
    for (const result of results) {
      const url = `${baseUrl}/transaction?tcode=${encodeURIComponent(result.transactionCode)}`;
      await actionPage.goto(url, {waitUntil: "load"});
      await actionPage.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
      const inventory = await inventoryReferenceActions(actionPage);
      const initialPageKind = await actionPage.locator("[data-page-kind]").getAttribute("data-page-kind");
      const testedSubmitControls = inventory.submitControls.filter((item) =>
        !(initialPageKind === "SELECTION" && item.value.toUpperCase() === "EXIT"));
      const journey = [];

      for (const action of testedSubmitControls.filter((item) => !item.disabled)) {
        await actionPage.goto(url, {waitUntil: "load"});
        await actionPage.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
        const beforePageId = await actionPage.locator("[data-page-kind]").getAttribute("data-page-id");
        const before = await programOwnedFingerprint(actionPage);
        const controls = actionPage.locator(".wb-runtime-content button[type=submit], .wb-runtime-content input[type=submit]");
        const lineNumber = /^LINE:(\d+)\|/.exec(action.value)?.[1];
        const control = lineNumber
          ? actionPage.locator(`.wb-runtime-content [data-line-index="${lineNumber}"] button[type=submit]`)
          : controls.nth(action.index);
        assert.equal(await control.isVisible(), true, `${result.programName} action ${action.label} is not visible on its fresh journey`);
        let response;
        try {
          [response] = await Promise.all([
            actionPage.waitForResponse(
              (candidate) => candidate.url().endsWith("/dispatch")
                && candidate.request().method() === "POST",
              {timeout: 30_000}),
            control.click({noWaitAfter: true}),
          ]);
          await actionPage.waitForLoadState("load");
        } catch (error) {
          throw new Error(`${result.programName} action ${action.value || action.label} did not dispatch: ${error.message}`);
        }
        assert.equal(response?.status(), 200, `${result.programName} action ${action.value || action.label} did not return HTTP 200: ${await response?.text()}`);
        await actionPage.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
        const afterPageId = await actionPage.locator("[data-page-kind]").getAttribute("data-page-id");
        const after = await programOwnedFingerprint(actionPage);
        const programEffect = before !== after;
        const idempotentReason = idempotentActionReason(result.programName, action.value);
        assert.notEqual(afterPageId, beforePageId, `${result.programName} action ${action.value || action.label} did not create a new server-owned page state`);
        journey.push({kind: "submit", label: action.label, ucomm: action.value, stateChanged: programEffect, programEffect, idempotent: !programEffect && Boolean(idempotentReason), idempotentReason: idempotentReason || undefined, pageChanged: true});
      }

      for (const action of inventory.selectionChanges.filter((item) => item.ucomm && !item.disabled && (item.type !== "select" || item.optionCount > 1) && (item.type !== "radio" || !item.checked))) {
        await actionPage.goto(url, {waitUntil: "load"});
        await actionPage.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
        const beforePageId = await actionPage.locator("[data-page-kind]").getAttribute("data-page-id");
        const before = await programOwnedFingerprint(actionPage);
        const controls = actionPage.locator(".wb-runtime-content [data-selection-ucomm]");
        const control = controls.nth(action.index);
        assert.equal(await control.isVisible(), true, `${result.programName} selection action ${action.ucomm} is not visible on its fresh journey`);
        const responsePromise = actionPage.waitForResponse(
          (candidate) => candidate.url().endsWith("/dispatch")
            && candidate.request().method() === "POST",
          {timeout: 30_000});
        let changePromise;
        if (action.type === "select") {
          const options = await control.locator("option").count();
          changePromise = options > 1
            ? control.selectOption({index: 1, noWaitAfter: true})
            : control.selectOption({index: 0, noWaitAfter: true});
        } else if (action.type === "checkbox") {
          changePromise = action.checked
            ? control.uncheck({noWaitAfter: true})
            : control.check({noWaitAfter: true});
        } else if (action.type === "radio") {
          changePromise = control.check({noWaitAfter: true});
        } else {
          changePromise = control.dispatchEvent("change");
        }
        let response;
        try {
          [response] = await Promise.all([responsePromise, changePromise]);
        } catch (error) {
          throw new Error(`${result.programName} selection action ${action.ucomm} did not dispatch: ${error.message}`);
        }
        await actionPage.waitForLoadState("load");
        assert.equal(response?.status(), 200, `${result.programName} selection action ${action.ucomm} did not return HTTP 200`);
        await actionPage.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
        const afterPageId = await actionPage.locator("[data-page-kind]").getAttribute("data-page-id");
        const after = await programOwnedFingerprint(actionPage);
        const programEffect = before !== after;
        const idempotentReason = idempotentActionReason(result.programName, action.ucomm);
        assert.notEqual(afterPageId, beforePageId, `${result.programName} selection action ${action.ucomm} did not create a new server-owned page state`);
        journey.push({kind: "selection-change", label: action.label, ucomm: action.ucomm, stateChanged: programEffect, programEffect, idempotent: !programEffect && Boolean(idempotentReason), idempotentReason: idempotentReason || undefined, pageChanged: true});
      }

      await negativePage.goto(url, {waitUntil: "load"});
      await negativePage.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
      const forgedCommand = await postDispatch(negativePage, {action: "COMMAND", ucomm: "PLAN9_FORGED_FUNCTION"});
      assert.equal(forgedCommand.status, 400, `${result.programName} accepted a forged function code: ${forgedCommand.body}`);
      const forgedRow = await postDispatch(negativePage, {action: "LINE", row: 999, token: "PLAN9_FORGED_NODE"});
      assert.equal(forgedRow.status, 400, `${result.programName} accepted a forged row/node id: ${forgedRow.body}`);
      const unsafeMetadata = await postDispatch(negativePage, {
        action: "COMMAND",
        ucomm: "PLAN9_FORGED_METADATA",
        variant: "../../outside",
        path: "../../outside",
        url: "javascript:alert(1)",
        file_name: "../../outside.txt",
        mime_type: "text/plain",
      });
      assert.equal(unsafeMetadata.status, 400, `${result.programName} accepted forged variant/path/URL/upload metadata: ${unsafeMetadata.body}`);
      const disabled = inventory.submitControls.filter((item) => item.disabled && item.value);
      for (const control of disabled) {
        const disabledResult = await postDispatch(negativePage, {action: "COMMAND", ucomm: control.value});
        assert.equal(disabledResult.status, 400, `${result.programName} accepted disabled action ${control.value}: ${disabledResult.body}`);
      }
      const programEffectPassed = journey.every((item) => item.programEffect === true || item.idempotent === true);
      result.interactionAudit = {
        status: programEffectPassed ? "passed" : "failed",
        visibleActionCount: testedSubmitControls.length + inventory.selectionChanges.length,
        journeyCount: journey.length,
        journeys: journey,
        programEffectGate: {
          status: programEffectPassed ? "passed" : "failed",
          rule: "Every exercised action changes a program-owned application surface, or is explicitly verified as fresh-session idempotent.",
          evidence: programEffectPassed
            ? "Every exercised action changed the report-owned .gg-page fingerprint or matched a named fresh-session idempotence contract."
            : "At least one exercised action changed only host chrome or server metadata without an explicit idempotence contract.",
        },
        disabledActionCount: disabled.length,
        negativeCases: {
          forgedFunctionCode: "passed",
          forgedRowOrNodeId: "passed",
          forgedVariantPathUrlUploadMetadata: "passed",
          disabledControls: "passed",
        },
        evidence: `Fresh-session journeys dispatched ${journey.length} enabled visible application action(s); ${journey.filter((item) => item.programEffect).length} changed the program-owned application fingerprint, and every forged command, row/node id, unsafe metadata request, and disabled action was rejected by the server.`,
      };
    }
  } finally {
    await actionPage.close();
    await negativePage.close();
  }
}

function applyComparisonGates(results, comparisonSummary) {
  const comparisons = new Map((comparisonSummary.comparisons ?? []).map((item) => [item.name.toLowerCase(), item]));
  for (const result of results) {
    const comparison = comparisons.get(`${result.programName.toLowerCase()}.png`);
    const semanticPassed = result.smokeTest?.status === "passed";
    const behaviorPassed = result.interactionAudit?.status === "passed"
      && Object.values(result.interactionAudit.negativeCases ?? {}).every((status) => status === "passed")
      && (result.interactionAudit.journeys ?? []).every((journey) => journey.pageChanged === true && (journey.programEffect === true || journey.idempotent === true));
    const stateChangedCount = (result.interactionAudit?.journeys ?? []).filter((journey) => journey.programEffect === true).length;
    const idempotentCount = (result.interactionAudit?.journeys ?? []).filter((journey) => journey.idempotent === true).length;
    const journeyCount = result.interactionAudit?.journeyCount ?? 0;
    const visualPassed = result.visualStructureAudit?.status === "passed";
    result.comparisonGates = {
      semanticContent: {
        status: semanticPassed ? "passed" : "failed",
        rule: comparisonGateDefinitions[0].rule,
        evidence: semanticPassed
          ? `Report-specific ${result.smokeTest.pageKind} content rendered with headings and no generic partial-conversion heading.`
          : "The first-screen semantic smoke test did not pass.",
      },
      interactiveBehavior: {
        status: behaviorPassed ? "passed" : "failed",
        rule: comparisonGateDefinitions[1].rule,
        evidence: behaviorPassed
          ? `${stateChangedCount} fresh-session journeys changed program-owned state; ${idempotentCount} named lifecycle journeys were verified idempotent; forged and disabled actions were rejected.`
          : `${stateChangedCount} of ${journeyCount} fresh-session journeys changed server-owned page state and no explicit idempotence contract covered the remainder.`,
      },
      visualStructure: {
        status: visualPassed ? "passed" : "failed",
        rule: comparisonGateDefinitions[2].rule,
        evidence: visualPassed
          ? `${result.visualStructureAudit.evidence} Pixel evidence remains available separately${comparison ? ` (${comparison.changedPixels} changed of ${comparison.totalPixels}).` : "."}`
          : comparison
            ? `The normalized screenshot differs in ${comparison.changedPixels} of ${comparison.totalPixels} pixels; visual parity remains open.`
            : result.visualStructureAudit?.evidence || "No normalized screenshot comparison was produced.",
      },
    };
    result.comparisonAccepted = Object.values(result.comparisonGates).every((gate) => gate.status === "passed");
  }
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
    const activationStatus = result.activation?.status || "pending";
    const parityCandidate = result.applicationParityCandidate === true;
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
    const accepted = result.comparisonAccepted === true;
    return `<article class="comparison-card comparison-card--${status}" id="${escapeHtml(result.programName.toLowerCase())}" data-program="${escapeHtml(result.programName)}" data-conversion-status="${status}" data-activation-status="${escapeHtml(activationStatus)}" data-application-parity-candidate="${parityCandidate}" data-comparison-accepted="${accepted}">
  <header><h2>${escapeHtml(result.programName)}</h2><span class="status">${statusLabel}</span><span class="comparison-status">${accepted ? "accepted" : "not accepted"}</span><span class="activation-status">Activation: ${escapeHtml(activationStatus)}</span><span class="diagnostic-count">${diagnosticSummary}</span></header>
  <div class="panels">
    <figure><figcaption>Generated browser <span>${dimensionsText(generated?.dimensions)}</span></figcaption>${imageMarkup({info: generated, alt: `${result.programName} generated browser screen`, missingLabel: "Generated image not present"})}</figure>
    <figure><figcaption>SAP GUI reference <span>${dimensionsText(reference?.dimensions)}</span></figcaption>${imageMarkup({info: reference, alt: `${result.programName} SAP GUI reference`, missingLabel: "Reference image not present"})}</figure>
    <figure><figcaption>Optional pixel diff <span>${dimensionsText(diff?.dimensions)}</span></figcaption>${imageMarkup({info: diff, alt: `${result.programName} pixel difference`, missingLabel: "No diff image generated"})}</figure>
  </div>
  <p class="metadata"><strong>Reference dimensions:</strong> ${dimensionsText(reference?.dimensions)}<br><strong>Target:</strong> ${escapeHtml(result.targetClass)} - <strong>Transaction:</strong> ${escapeHtml(result.transactionCode)}<br><strong>Application-parity candidate:</strong> ${parityCandidate ? "yes" : "no"}<br><strong>First-screen smoke:</strong> ${escapeHtml(result.smokeTest?.status || "not-run")}${result.smokeTest?.pageKind ? ` (${escapeHtml(result.smokeTest.pageKind)})` : ""}<br><strong>Interaction audit:</strong> ${escapeHtml(result.interactionAudit?.status || "not-run")}${result.interactionAudit?.journeyCount !== undefined ? ` (${escapeHtml(result.interactionAudit.journeyCount)} journeys)` : ""}</p>
  ${referenceAudit ? `<section class="reference-audit" data-reference-audit="${escapeHtml(referenceAudit.status)}"><h3>Reference audit: ${escapeHtml(referenceAudit.acceptance)}</h3><p><strong>Observed:</strong> ${escapeHtml(referenceAudit.observedState)}<br><strong>Intended:</strong> ${escapeHtml(referenceAudit.intendedState)}${referenceAudit.verification ? `<br><strong>Verification:</strong> ${escapeHtml(referenceAudit.verification)}` : ""}</p></section>` : ""}
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
      .activation-status { padding: .3rem .6rem; border-radius: 999px; color: #704900; background: #fff1cc; font-size: .9rem; font-weight: 650; }
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
  <p class="intro">${results.length} reports from ${escapeHtml(revision)}. Browser capture viewport: ${screenshotViewport.width} x ${screenshotViewport.height}; locale ${escapeHtml(screenshotEnvironment.locale)}; timezone ${escapeHtml(screenshotEnvironment.timezone)}; animations ${escapeHtml(screenshotEnvironment.animations)}. Deterministic fixture: ${screenshotFixture.date} ${screenshotFixture.time} UTC, user ${escapeHtml(screenshotFixture.user)}, path ${escapeHtml(screenshotFixture.tempDirectory)}, URL ${escapeHtml(screenshotFixture.externalUrl)}. Each card includes the generated browser screen, the SAP GUI reference, and an optional diff image. Comparison acceptance requires semantic-content, interactive-behavior, and visual-structure gates; pixel similarity is evidence only. See the <a href="../reference-audit.json">reference audit</a> and <a href="../fallback-audit.json">fallback audit</a>.</p>
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
  const conversionOptions = {
    source,
    filename,
    className,
    transactionCode: transactionCode(programName),
    description: `Converted gg-gui report ${programName}`,
    mode: "partial",
    resolveInclude,
    screenMetadata,
    ddicTypes: GG_GUI_DDIC_TYPES,
  };
  const supportProbe = await convertProgram({...conversionOptions, partialStrategy: "preserve"});
  const hasFatalDiagnostic = supportProbe.diagnostics.some((diagnostic) => diagnostic.severity === "error");
  const result = supportProbe.classSource && !hasFatalDiagnostic
    ? supportProbe
    : await convertProgram({...conversionOptions, partialStrategy: "skeleton"});
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
    smokeTest: pendingSmokeTest(),
    interactionAudit: {status: "not-run"},
    visualContract: visualContractFor(programName, screenMetadata),
    visualStructureAudit: {status: "not-run"},
    comparisonAccepted: false,
    comparisonGates: pendingComparisonGates(),
    fallbackAudit: intentionalReferenceFallbacks[programName] || null,
    knownFailing: isKnownFailingReport(programName),
    generatedClasses: [result.manifest.targetClass, ...(result.helperSources ?? []).map((helper) => helper.className)],
    activation: {status: "pending", tool: "abap_transpile"},
    applicationParityCandidate: false,
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
await fs.writeFile(path.join(validationRoot, "known-failing.json"), `${JSON.stringify({
  repositoryUrl,
  revision,
  phase: "Current known-failing baseline",
  reports: knownFailingReports.map((programName) => ({
    programName,
    reason: "The report is retained as a known failing conversion until its own logic and program-owned effects are functional.",
  })),
}, null, 2)}\n`, "utf8");
await fs.writeFile(path.join(validationRoot, "results.json"), `${JSON.stringify({repositoryUrl, revision, screenshotViewport, screenshotFixture, screenshotEnvironment, comparisonGateDefinitions, knownFailingReports, reports: results}, null, 2)}\n`, "utf8");
console.log(`Converted ${results.length} gg-gui reports from ${revision}`);

await runCommand(repositoryTool("abap_transpile"), [path.relative(repositoryRoot, transpileConfigPath)]);

for (const result of results) {
  const outputChecks = await Promise.all(result.generatedClasses.map(async (className) => ({
    className,
    present: await exists(path.join(outputRoot, `${className.toLowerCase()}.clas.mjs`)),
  })));
  const missing = outputChecks.filter((item) => !item.present).map((item) => item.className);
  assert.equal(missing.length, 0, `${result.programName} generated classes missing transpiler output: ${missing.join(", ")}`);
  result.activation = {
    status: "passed",
    tool: "abap_transpile",
    classes: [...result.generatedClasses],
  };
  result.applicationParityCandidate = true;
}
await fs.writeFile(path.join(validationRoot, "results.json"), `${JSON.stringify({repositoryUrl, revision, screenshotViewport, screenshotFixture, screenshotEnvironment, comparisonGateDefinitions, knownFailingReports, reports: results}, null, 2)}\n`, "utf8");

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
  const page = await newScreenshotPage(browser);
  for (const result of results) {
    assert.equal(result.applicationParityCandidate, true, `Screenshot blocked until ${result.programName} has clean transpiler activation`);
    const response = await page.goto(`${baseUrl}/transaction?tcode=${encodeURIComponent(result.transactionCode)}`, {waitUntil: "load"});
    assert.equal(response?.status(), 200, `Host failed for ${result.programName}`);
    await page.locator("[data-page-kind]").waitFor({state: "visible", timeout: 30_000});
    const smoke = await page.locator("body").evaluate((body) => ({
      text: body.innerText,
      headings: [...body.querySelectorAll("h1, h2, h3")].map((heading) => heading.textContent?.trim() || ""),
      pageKind: body.querySelector("[data-page-kind]")?.getAttribute("data-page-kind") || "",
    }));
    const reportSpecificNames = [result.programName, result.targetClass, result.transactionCode, result.visualContract?.title].filter(Boolean);
    const reportSpecificName = reportSpecificNames.find((name) => smoke.text.includes(name));
    const reportSpecificTokens = reportSpecificNames
      .flatMap((name) => name.split("_"))
      .filter((token) => token.length >= 4 && !["ZGG", "GUI", "ZCL", "CV"].includes(token));
    const matchingTokens = [...new Set(reportSpecificTokens.filter((token) => smoke.text.toUpperCase().includes(token)))];
    assert.ok(reportSpecificName || matchingTokens.length > 0, `${result.programName} first screen has no report-specific content`);
    assert.equal(hasGenericPartialHeading(smoke.headings), false, `${result.programName} first screen exposes a generic partial-conversion heading`);
    assert.ok(smoke.pageKind, `${result.programName} first screen has no page kind`);
    result.smokeTest = {
      status: "passed",
      pageKind: smoke.pageKind,
      headings: smoke.headings,
      evidence: `Report-specific content ${reportSpecificName || matchingTokens.join(", ")} rendered on ${smoke.pageKind}; no generic partial-conversion heading found.`,
    };
    result.visualStructureAudit = await auditVisualStructure(page, result);
    await waitForDeterministicFonts(page);
    await page.screenshot({path: path.join(screenshotsRoot, `${result.programName.toLowerCase()}.png`), fullPage: true});
  }
  await runReferenceInteractionAudit(browser, baseUrl, results);
  const variantsPage = await newScreenshotPage(browser);
  variantsPage.on("dialog", async (dialog) => dialog.accept());
  const variantsUrl = `${baseUrl}/transaction?tcode=${encodeURIComponent("CV_SEL_VARIANTS")}`;
  await variantsPage.goto(variantsUrl, {waitUntil: "load"});
  await variantsPage.locator('[name="P_VARI"]').fill("GG_E2E");
  await variantsPage.locator('[name="P_NAME"]').fill("Created value");
  await variantsPage.locator('button[name="gg_ucomm"][value="SAVE"]').click();
  await variantsPage.waitForLoadState("load");
  assert.match(await variantsPage.locator("body").textContent(), /Variant GG_E2E was created/);
  await variantsPage.locator('[name="P_NAME"]').fill("Updated value");
  await variantsPage.locator('button[name="gg_ucomm"][value="SAVE"]').click();
  await variantsPage.waitForLoadState("load");
  assert.match(await variantsPage.locator("body").textContent(), /Variant GG_E2E was updated/);
  await variantsPage.locator('[name="P_NAME"]').fill("Unsaved value");
  await variantsPage.locator('button[name="gg_ucomm"][value="SHOW"]').click();
  await variantsPage.waitForLoadState("load");
  assert.match(await variantsPage.locator("body").textContent(), /S_CAT kind S/);
  await variantsPage.locator('button[name="gg_ucomm"][value="SUBVAR"]').click();
  await variantsPage.waitForLoadState("load");
  await variantsPage.getByRole("button", {name: "Continue", exact: true}).click();
  await variantsPage.waitForLoadState("load");
  await variantsPage.getByRole("button", {name: "BACK", exact: true}).click();
  await variantsPage.waitForLoadState("load");
  assert.match(await variantsPage.locator("body").textContent(), /Returned from the report started with USING SELECTION-SET/);
  await variantsPage.goto(variantsUrl, {waitUntil: "load"});
  await variantsPage.locator('[name="P_VARI"]').fill("GG_E2E");
  await variantsPage.locator('button[name="gg_ucomm"][value="DELETE"]').click();
  await variantsPage.waitForLoadState("load");
  assert.match(await variantsPage.locator("body").textContent(), /Variant GG_E2E was deleted/);
  await variantsPage.close();
  const freePage = await newScreenshotPage(browser);
  const freeUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_SEL_FREE");
  await freePage.goto(freeUrl, {waitUntil: "load"});
  await freePage.locator('button[name="gg_ucomm"][value="DLGWIN"]').click();
  await freePage.waitForLoadState("load");
  assert.equal(await freePage.locator('[data-free-selection="true"]').count(), 1);
  assert.equal(await freePage.getByRole("dialog").getAttribute("aria-modal"), "true");
  await freePage.locator('[name="gg-free-SPRSL-LOW"]').fill("EN");
  await freePage.locator('[name="gg_free_action"][value="APPLY"]').click();
  await freePage.waitForLoadState("load");
  assert.equal(await freePage.locator('[data-free-selection="true"]').count(), 0);
  assert.match(await freePage.locator("body").textContent(), /Converted WHERE T100/);
  await freePage.locator('button[name="gg_ucomm"][value="DLGFULL"]').click();
  await freePage.waitForLoadState("load");
  assert.equal(await freePage.locator(".gg-free-selection-modal--fullscreen").count(), 1);
  await freePage.locator('[name="gg_free_action"][value="CANCEL"]').click();
  await freePage.waitForLoadState("load");
  assert.equal(await freePage.locator('[data-free-selection="true"]').count(), 0);
  await freePage.locator('button[name="gg_ucomm"][value="RESET"]').click();
  await freePage.waitForLoadState("load");
  assert.match(await freePage.locator("body").textContent(), /Dynamic selection, field list,/);
  await freePage.locator('button[name="gg_ucomm"][value="DLGWIN"]').click();
  await freePage.waitForLoadState("load");
  await freePage.locator('[name="gg-free-SPRSL-LOW"]').fill("EN");
  await freePage.locator('[name="gg_free_action"][value="APPLY"]').click();
  await freePage.waitForLoadState("load");
  await freePage.locator('button[name="gg_ucomm"][value="ONLI"]').click();
  await freePage.waitForLoadState("load");
  assert.equal(await freePage.locator('[data-page-kind="LIST"]').count(), 1);
  assert.match(await freePage.locator("body").textContent(), /Range T100-SPRSL/);
  assert.match(await freePage.locator("body").textContent(), /Converted WHERE T100|WHERE T100/);
  await freePage.close();
  const dynproPage = await newScreenshotPage(browser);
  const dynproUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_DYNPRO_ELEMENTS");
  await dynproPage.goto(dynproUrl, {waitUntil: "load"});
  assert.equal(await dynproPage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  assert.equal(await dynproPage.locator(".gg-dynpro fieldset").count(), 2);
  assert.equal(await dynproPage.locator('[name="GV_TEXT"]').inputValue(), "Editable text");
  assert.equal(await dynproPage.locator('[name="GV_SECRET"]').getAttribute("type"), "password");
  assert.equal(await dynproPage.locator('output[id*="GV_ICON"] .wb-icon').count(), 1);
  assert.equal(await dynproPage.locator('[name="GV_LIST"] option').count(), 3);
  assert.equal(await dynproPage.locator('[name="GV_LIST"]').inputValue(), "ONE");
  assert.equal(await dynproPage.locator('input[type="checkbox"][name="GV_CHECK"]').isChecked(), true);
  assert.equal(await dynproPage.locator('input[type="radio"][data-abap-name="GV_RADIO_A"]').isChecked(), true);
  assert.ok((await dynproPage.locator('input[name="GV_DATE"]').inputValue()).length > 0);
  assert.ok((await dynproPage.locator('input[name="GV_TIME"]').inputValue()).length > 0);
  await dynproPage.locator('[name="GV_TEXT"]').fill("Changed text");
  await dynproPage.locator('input[type="checkbox"][name="GV_CHECK"]').uncheck();
  await dynproPage.locator('[name="GV_LIST"]').selectOption("TWO");
  await dynproPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await dynproPage.waitForLoadState("load");
  assert.equal(await dynproPage.locator('[name="GV_TEXT"]').inputValue(), "Changed text");
  assert.equal(await dynproPage.locator('input[type="checkbox"][name="GV_CHECK"]').isChecked(), false);
  assert.equal(await dynproPage.locator('[name="GV_LIST"]').inputValue(), "TWO");
  assert.match(await dynproPage.locator('output[id*="GV_OUTPUT"]').textContent(), /Applied TWO, PBO pass/);
  await dynproPage.locator('button[name="gg_ucomm"][value="RESET"]').click();
  await dynproPage.waitForLoadState("load");
  assert.equal(await dynproPage.locator('[name="GV_TEXT"]').inputValue(), "Editable text");
  assert.equal(await dynproPage.locator('input[type="checkbox"][name="GV_CHECK"]').isChecked(), true);
  assert.equal(await dynproPage.locator('[name="GV_LIST"]').inputValue(), "ONE");
  assert.match(await dynproPage.locator('output[id*="GV_OUTPUT"]').textContent(), /Values reset/);
  await dynproPage.locator('button[name="gg_ucomm"][value="BACK"]').click();
  await dynproPage.waitForLoadState("load");
  assert.equal(await dynproPage.locator('[data-screen="0000"]').count(), 1);
  await dynproPage.close();
  const flowPage = await newScreenshotPage(browser);
  const flowUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_DYNPRO_FLOW");
  await flowPage.goto(flowUrl, {waitUntil: "load"});
  assert.equal(await flowPage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  assert.equal(await flowPage.locator(".gg-dynpro fieldset").count(), 2);
  assert.equal(await flowPage.locator('[name="GV_FIRST"]').inputValue(), "Ada");
  assert.equal(await flowPage.locator('[name="GV_LAST"]').inputValue(), "Lovelace");
  assert.equal(await flowPage.locator('input[type="checkbox"][name="GV_ENABLE"]').isChecked(), true);
  assert.equal(await flowPage.locator('[name="GV_DYNAMIC"]').isVisible(), true);
  assert.match(await flowPage.locator("body").textContent(), /PBO: STATUS_0100/);
  await flowPage.locator('[name="GV_REQUEST"]').fill("typed request");
  await flowPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await flowPage.waitForLoadState("load");
  assert.equal(await flowPage.locator('[name="GV_REQUEST"]').inputValue(), "typed request");
  assert.match(await flowPage.locator("body").textContent(), /Validated Ada Lovelace/);
  assert.match(await flowPage.locator("body").textContent(), /PAI: OBSERVE_REQUEST ON INPUT/);
  assert.match(await flowPage.locator("body").textContent(), /PAI: VALIDATE_NAME ON CHAIN-REQUEST/);
  await flowPage.locator('[name="GV_FIRST"]').fill("");
  await flowPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await flowPage.waitForLoadState("load");
  assert.equal(await flowPage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  assert.match(await flowPage.locator("body").textContent(), /Enter a first name/);
  await flowPage.locator('[name="GV_FIRST"]').fill("Ada");
  await flowPage.locator('input[type="checkbox"][name="GV_ENABLE"]').uncheck();
  await flowPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await flowPage.waitForLoadState("load");
  await flowPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await flowPage.waitForLoadState("load");
  assert.equal(await flowPage.locator('[name="GV_DYNAMIC"]').isVisible(), false);
  await flowPage.locator('button[name="gg_ucomm"][value="RESET"]').click();
  await flowPage.waitForLoadState("load");
  assert.equal(await flowPage.locator('[name="GV_FIRST"]').inputValue(), "Ada");
  assert.equal(await flowPage.locator('[name="GV_LAST"]').inputValue(), "Lovelace");
  assert.equal(await flowPage.locator('[name="GV_REQUEST"]').inputValue(), "");
  assert.equal(await flowPage.locator('input[type="checkbox"][name="GV_ENABLE"]').isChecked(), true);
  await flowPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await flowPage.waitForLoadState("load");
  assert.equal(await flowPage.locator('[name="GV_DYNAMIC"]').isVisible(), true);
  await flowPage.locator('button[name="gg_ucomm"][value="FOCUS"]').click();
  await flowPage.waitForLoadState("load");
  await flowPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await flowPage.waitForLoadState("load");
  assert.equal(await flowPage.locator('.gg-dynpro[data-cursor-field="GV_FIRST"]').count(), 1);
  await flowPage.locator('button[name="gg_ucomm"][value="BACK"]').click();
  await flowPage.waitForLoadState("load");
  assert.equal(await flowPage.locator('[data-screen="0000"]').count(), 1);
  await flowPage.close();
  const cancelPage = await newScreenshotPage(browser);
  await cancelPage.goto(flowUrl, {waitUntil: "load"});
  await cancelPage.locator('button[name="gg_ucomm"][value="CANCEL"]').click();
  await cancelPage.waitForLoadState("load");
  assert.equal(await cancelPage.locator('[data-screen="0000"]').count(), 1);
  assert.match(await cancelPage.locator("body").textContent(), /Changes canceled/);
  await cancelPage.close();
  const tablePage = await newScreenshotPage(browser);
  const tableUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_TABLE_CONTROL");
  await tablePage.goto(tableUrl, {waitUntil: "load"});
  assert.equal(await tablePage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  const tableControl = tablePage.locator('[data-table-control]');
  assert.equal(await tableControl.count(), 1);
  assert.equal(await tableControl.locator("thead th").count(), 7);
  assert.equal(await tableControl.locator("tbody tr").count(), 15);
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-1"]').inputValue(), "Mechanical Keyboard");
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-4"]').inputValue(), "USB-C Dock");
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-QUANTITY-4"]').isDisabled(), true);
  await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-1"]').fill("Mechanical Keyboard Pro");
  await tablePage.locator('input[name="gg-cell-TC_ROWS-QUANTITY-1"]').fill("13");
  await tablePage.locator('input[name="gg-cell-TC_ROWS-PRICE-1"]').fill("139.90");
  await tablePage.locator('input[type="checkbox"][name="gg-cell-TC_ROWS-MARK-1"]').check();
  await tablePage.locator('button[name="gg_ucomm"][value="APPEND"]').click();
  await tablePage.waitForLoadState("load");
  assert.match(await tablePage.locator("body").textContent(), /A row was appended/);
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-1"]').inputValue(), "Mechanical Keyboard Pro");
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-6"]').inputValue(), "New product");
  await tablePage.locator('button[name="gg_ucomm"][value="COPY"]').click();
  await tablePage.waitForLoadState("load");
  assert.match(await tablePage.locator("body").textContent(), /copied/);
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-7"]').inputValue(), "Copy of Mechanical Keyboard Pro".slice(0, 30));
  await tablePage.locator('input[type="checkbox"][name="gg-cell-TC_ROWS-MARK-1"]').check();
  await tablePage.locator('button[name="gg_ucomm"][value="DELETE"]').click();
  await tablePage.waitForLoadState("load");
  assert.match(await tablePage.locator("body").textContent(), /marked row\(s\) deleted/);
  await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-1"]').fill("");
  await tablePage.locator('button[name="gg_ucomm"][value="APPEND"]').click();
  await tablePage.waitForLoadState("load");
  assert.match(await tablePage.locator("body").textContent(), /Enter a product name/);
  await tablePage.locator('button[name="gg_ucomm"][value="RESET"]').click();
  await tablePage.waitForLoadState("load");
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-1"]').inputValue(), "Mechanical Keyboard");
  assert.equal(await tablePage.locator('input[name="gg-cell-TC_ROWS-NAME-5"]').inputValue(), "Conference Speaker");
  await tablePage.locator('button[name="gg_ucomm"][value="BACK"]').click();
  await tablePage.waitForLoadState("load");
  assert.equal(await tablePage.locator('[data-screen="0000"]').count(), 1);
  await tablePage.close();
  const tabPage = await newScreenshotPage(browser);
  const tabUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_TABSTRIP");
  await tabPage.goto(tabUrl, {waitUntil: "load"});
  assert.equal(await tabPage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  assert.equal(await tabPage.locator('[role="tab"]').count(), 3);
  assert.match(await tabPage.locator("body").textContent(), /Identity: Ada Lovela/);
  assert.match(await tabPage.locator("body").textContent(), /Settings: notify/);
  assert.match(await tabPage.locator("body").textContent(), /Advanced/);
  assert.equal(await tabPage.locator('[name="GV_NAME"]').isVisible(), true);
  assert.equal(await tabPage.locator('[name="GV_START_DATE"]').count(), 0);
  await tabPage.getByRole("tab", {name: /Settings: notify/}).click();
  await tabPage.waitForLoadState("load");
  assert.equal(await tabPage.locator('[name="TS_MAIN-ACTIVETAB"]').inputValue(), "TAB2");
  assert.equal(await tabPage.locator('[name="GV_NAME"]').count(), 0);
  assert.equal(await tabPage.locator('[name="GV_START_DATE"]').isVisible(), true);
  await tabPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await tabPage.waitForLoadState("load");
  assert.match(await tabPage.locator("body").textContent(), /Active page TAB2 was applied/);
  await tabPage.getByRole("tab", {name: "Advanced", exact: true}).click();
  await tabPage.waitForLoadState("load");
  assert.equal(await tabPage.locator('[name="TS_MAIN-ACTIVETAB"]').inputValue(), "TAB3");
  assert.equal(await tabPage.locator('[name="GV_NAME"]').count(), 0);
  await tabPage.locator('input[type="checkbox"][name="GV_SHOW_ADVANCED"]').uncheck();
  await tabPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await tabPage.waitForLoadState("load");
  assert.equal(await tabPage.locator('[role="tab"]').count(), 2);
  assert.equal(await tabPage.locator('[name="TS_MAIN-ACTIVETAB"]').inputValue(), "TAB1");
  await tabPage.locator('button[name="gg_ucomm"][value="RESET"]').click();
  await tabPage.waitForLoadState("load");
  assert.equal(await tabPage.locator('[role="tab"]').count(), 3);
  assert.equal(await tabPage.locator('input[type="checkbox"][name="GV_SHOW_ADVANCED"]').isChecked(), true);
  await tabPage.locator('button[name="gg_ucomm"][value="CLIENT"]').click();
  await tabPage.waitForLoadState("load");
  assert.equal(await tabPage.locator('[data-screen="0200"]').count(), 1);
  assert.equal(await tabPage.locator('[role="tab"]').count(), 3);
  assert.equal(await tabPage.locator('[name="GV_NAME"]').isVisible(), true);
  assert.equal(await tabPage.locator('[name="GV_START_DATE"]').count(), 0);
  await tabPage.locator('button[name="gg_ucomm"][value="BACK"]').click();
  await tabPage.waitForLoadState("load");
  assert.equal(await tabPage.locator('[data-screen="0000"]').count(), 1);
  await tabPage.close();
  const subscreenPage = await newScreenshotPage(browser);
  const subscreenUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_SUBSCREENS");
  await subscreenPage.goto(subscreenUrl, {waitUntil: "load"});
  assert.equal(await subscreenPage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  assert.equal(await subscreenPage.locator('[data-screen="0100"]').count(), 1);
  assert.match(await subscreenPage.locator("body").textContent(), /Parent sees: Shared left value \/ Details variant A/);
  assert.equal(await subscreenPage.locator('[name="GV_LEFT_VALUE"]').isVisible(), true);
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_A"]').isVisible(), true);
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_B"]').count(), 0);
  assert.match(await subscreenPage.locator('[name="GV_LEFT_VALUE"]').locator("xpath=../..").getAttribute("style"), /left:50px/);
  assert.match(await subscreenPage.locator('[name="GV_RIGHT_A"]').locator("xpath=../..").getAttribute("style"), /left:580px/);
  await subscreenPage.locator('button[name="gg_ucomm"][value="SWAP"]').click();
  await subscreenPage.waitForLoadState("load");
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_A"]').count(), 0);
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_B"]').isVisible(), true);
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_SCREEN"]').inputValue(), "0130");
  await subscreenPage.locator('button[name="gg_ucomm"][value="SUBNAV"]').click();
  await subscreenPage.waitForLoadState("load");
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_SCREEN"]').inputValue(), "0120");
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_A"]').isVisible(), true);
  assert.match(await subscreenPage.locator("body").textContent(), /Parent accepted subscreen request for screen 0120/);
  await subscreenPage.locator('button[name="gg_ucomm"][value="APPLY"]').click();
  await subscreenPage.waitForLoadState("load");
  assert.match(await subscreenPage.locator("body").textContent(), /Parent and both active subscreens completed PAI/);
  await subscreenPage.locator('button[name="gg_ucomm"][value="RESET"]').click();
  await subscreenPage.waitForLoadState("load");
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_SCREEN"]').inputValue(), "0120");
  assert.equal(await subscreenPage.locator('[name="GV_RIGHT_A"]').inputValue(), "Details variant A");
  await subscreenPage.locator('button[name="gg_ucomm"][value="BACK"]').click();
  await subscreenPage.waitForLoadState("load");
  assert.equal(await subscreenPage.locator('[data-screen="0000"]').count(), 1);
  await subscreenPage.close();
  const dialogsPage = await newScreenshotPage(browser);
  const dialogsUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_DIALOGS_HELP");
  await dialogsPage.goto(dialogsUrl, {waitUntil: "load"});
  assert.equal(await dialogsPage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  assert.equal(await dialogsPage.locator('[data-screen="0100"]').count(), 1);
  assert.equal(await dialogsPage.locator('[name="GV_CHOICE"]').inputValue(), "ALPHA");
  const choiceHelp = dialogsPage.getByRole("button", {name: "Value help for GV_CHOICE"});
  assert.equal(await choiceHelp.isVisible(), true);
  await dialogsPage.locator('[name="GV_CHOICE"]').focus();
  assert.equal(await choiceHelp.isVisible(), true);
  await dialogsPage.keyboard.press("F4");
  await dialogsPage.waitForLoadState("load");
  await dialogsPage.locator('.gg-value-help-modal[data-help-field="GV_CHOICE"]').waitFor({state: "visible"});
  const choiceValues = dialogsPage.getByRole("region", {name: "Value help"});
  assert.deepEqual(await choiceValues.locator("li").allTextContents(), ["ALPHA", "BETA", "GAMMA"]);
  await choiceValues.locator('li[data-value="BETA"]').dblclick();
  assert.equal(await dialogsPage.locator('[name="GV_CHOICE"]').inputValue(), "BETA");
  assert.equal(await dialogsPage.getByRole("dialog", {name: "Value help"}).isVisible(), false);
  assert.equal(await dialogsPage.locator('[name="GV_CHOICE"]').evaluate((field) => field === field.ownerDocument.activeElement), true);
  await dialogsPage.locator('[name="GV_CHOICE"]').press("F1");
  await dialogsPage.waitForLoadState("load");
  const helpPopup = dialogsPage.locator('.gg-popup-modal[data-popup-kind="INFORM"]');
  assert.equal(await helpPopup.count(), 1);
  assert.match(await helpPopup.textContent(), /Choice field help/);
  assert.match(await helpPopup.textContent(), /Use F4 to choose ALPHA, BETA, or GAMMA/);
  await helpPopup.getByRole("button", {name: "Close", exact: true}).click();
  await dialogsPage.waitForLoadState("load");
  assert.equal(await dialogsPage.locator('.gg-popup-modal[data-popup-kind="INFORM"]').count(), 0);
  assert.match(await dialogsPage.locator("body").textContent(), /Custom F1 help was displayed/);
  await dialogsPage.locator('button[name="gg_ucomm"][value="DIALOG"]').click();
  await dialogsPage.waitForLoadState("load");
  const dialogScreen = dialogsPage.locator('[data-screen="0200"]');
  assert.equal(await dialogScreen.count(), 1);
  assert.equal(await dialogScreen.getAttribute("data-modal"), "true");
  assert.match(await dialogScreen.getAttribute("style"), /margin-left:50px/);
  assert.match(await dialogScreen.getAttribute("style"), /margin-top:260px/);
  await dialogsPage.locator('[name="GV_DIALOG_TEXT"]').fill("Accepted text");
  await dialogsPage.locator('button[name="gg_ucomm"][value="OK"]').click();
  await dialogsPage.waitForLoadState("load");
  assert.equal(await dialogsPage.locator('[data-screen="0100"]').count(), 1);
  assert.match(await dialogsPage.locator("body").textContent(), /Modal dialog: Accepted: Accepted text/);
  await dialogsPage.locator('button[name="gg_ucomm"][value="CONFIRM"]').click();
  await dialogsPage.waitForLoadState("load");
  const confirmPopup = dialogsPage.locator('.gg-popup-modal[data-popup-kind="CONFIRM"]');
  assert.equal(await confirmPopup.count(), 1);
  assert.match(await confirmPopup.textContent(), /Apply the current choice/);
  await confirmPopup.getByRole("button", {name: "Cancel", exact: true}).click();
  await dialogsPage.waitForLoadState("load");
  assert.match(await dialogsPage.locator("body").textContent(), /Confirmation canceled or closed/);
  await dialogsPage.locator('button[name="gg_ucomm"][value="VALUE"]').click();
  await dialogsPage.waitForLoadState("load");
  const valuesPopup = dialogsPage.locator('.gg-popup-modal[data-popup-kind="VALUES"]');
  assert.equal(await valuesPopup.count(), 1);
  await valuesPopup.locator('[name="gg-popup-UNAME"]').fill("DELTA");
  await valuesPopup.getByRole("button", {name: "Apply", exact: true}).click();
  await dialogsPage.waitForLoadState("load");
  assert.equal(await dialogsPage.locator('[name="GV_CHOICE"]').inputValue(), "DELTA");
  assert.match(await dialogsPage.locator("body").textContent(), /Value popup returned DELTA/);
  await dialogsPage.locator('button[name="gg_ucomm"][value="INFO"]').click();
  await dialogsPage.waitForLoadState("load");
  const infoPopup = dialogsPage.locator('.gg-popup-modal[data-popup-kind="INFORM"]');
  assert.equal(await infoPopup.count(), 1);
  assert.match(await infoPopup.textContent(), /This popup does not change application state/);
  await infoPopup.getByRole("button", {name: "Close", exact: true}).click();
  await dialogsPage.waitForLoadState("load");
  assert.match(await dialogsPage.locator("body").textContent(), /Information popup closed/);
  await dialogsPage.locator('button[name="gg_ucomm"][value="PROGRESS"]').click();
  await dialogsPage.waitForLoadState("load");
  assert.match(await dialogsPage.locator("body").textContent(), /Progress indication completed/);
  await dialogsPage.locator('button[name="gg_ucomm"][value="BACK"]').click();
  await dialogsPage.waitForLoadState("load");
  assert.equal(await dialogsPage.locator('[data-screen="0000"]').count(), 1);
  await dialogsPage.close();
  const statusPage = await newScreenshotPage(browser);
  const statusUrl = baseUrl + "/transaction?tcode=" + encodeURIComponent("CV_GUI_STATUS");
  await statusPage.goto(statusUrl, {waitUntil: "load"});
  assert.equal(await statusPage.locator('[data-page-kind="DYNPRO"]').count(), 1);
  assert.equal(await statusPage.locator('[data-screen="0100"]').count(), 1);
  assert.match(await statusPage.locator("body").textContent(), /GUI Status Sample: Normal/);
  assert.equal(await statusPage.locator('.wb-app-toolbar button[aria-label="Apply"]').count(), 1);
  assert.equal(await statusPage.locator('.wb-app-toolbar button[aria-label="Reset"]').count(), 1);
  assert.equal(await statusPage.locator('.wb-app-toolbar button[aria-label="Toggle"]').count(), 1);
  assert.equal(await statusPage.locator('[data-menu-code="000001"]').count(), 1);
  assert.equal(await statusPage.locator('[data-menu-code="000002"]').count(), 1);
  const statusInput = statusPage.locator('[name="GV_INPUT"]');
  assert.equal(await statusInput.getAttribute("data-context-menu"), "true");
  const contextMenu = statusPage.locator('.gg-context-menu[data-context-menu-for="GV_INPUT"]');
  await statusInput.click({button: "right"});
  assert.equal(await contextMenu.isVisible(), true);
  assert.equal(await contextMenu.locator('button[name="gg_ucomm"][value="CTX_UPPER"]').count(), 1);
  await contextMenu.locator('button[name="gg_ucomm"][value="CTX_UPPER"]').click();
  await statusPage.waitForLoadState("load");
  assert.equal(await statusInput.inputValue(), "RIGHT-CLICK THIS FIELD");
  assert.match(await statusPage.locator("body").textContent(), /converted the value to upper case/);
  await statusPage.locator('.wb-app-toolbar button[aria-label="Toggle"]').click();
  await statusPage.waitForLoadState("load");
  assert.match(await statusPage.locator("body").textContent(), /GUI Status Sample: Apply excluded/);
  assert.equal(await statusPage.locator('.wb-app-toolbar button[aria-label="Apply"]').isDisabled(), true);
  await statusPage.locator('.wb-app-toolbar button[aria-label="Reset"]').click();
  await statusPage.waitForLoadState("load");
  await statusPage.locator('input[type="checkbox"][name="GV_DISABLE_CONTEXT"]').check();
  await statusPage.locator('.wb-app-toolbar button[aria-label="Toggle"]').click();
  await statusPage.waitForLoadState("load");
  await statusPage.locator('[name="GV_INPUT"]').click({button: "right"});
  assert.equal(await contextMenu.locator('button[name="gg_ucomm"][value="CTX_UPPER"]').isDisabled(), true);
  await Promise.all([
    statusPage.waitForNavigation({waitUntil: "load"}),
    statusPage.evaluate(() => document.dispatchEvent(new KeyboardEvent("keydown", {
      key: "F14",
      code: "F14",
      bubbles: true,
      cancelable: true,
    }))),
  ]);
  assert.match(await statusPage.locator("body").textContent(), /GUI Status Sample: Normal/);
  assert.equal(await statusPage.locator('.wb-app-toolbar button[aria-label="Apply"]').isDisabled(), false);
  await statusPage.close();
  await writeScreenshotIndex(results, revision, referenceRoot);
  await runCommand(process.execPath, [
    path.join(repositoryRoot, "test", "generate-screenshot-diffs.mjs"),
    referenceRoot,
    screenshotsRoot,
    diffRoot,
  ]);
  const comparisonSummary = JSON.parse(await fs.readFile(path.join(diffRoot, "summary.json"), "utf8"));
  applyComparisonGates(results, comparisonSummary);
  await writeScreenshotIndex(results, revision, referenceRoot);
  await fs.writeFile(path.join(validationRoot, "results.json"), `${JSON.stringify({repositoryUrl, revision, screenshotViewport, screenshotFixture, screenshotEnvironment, comparisonGateDefinitions, knownFailingReports, reports: results}, null, 2)}\n`, "utf8");
} finally {
  await browser?.close();
  await stopProcess(hostProcess);
}

const screenshots = (await fs.readdir(screenshotsRoot)).filter((name) => name.endsWith(".png"));
assert.equal(screenshots.length, results.length, "Expected one screenshot per gg-gui report");
console.log(`Captured ${screenshots.length} report screenshots in ${screenshotsRoot}`);
