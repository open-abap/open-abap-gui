import assert from "node:assert/strict";
import fs from "node:fs";
import {createHtmlHostServer} from "../host/html-http.mjs";
import {chromium} from "playwright-core";

const chromeCandidates = [
  process.env.CHROME_PATH,
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
].filter(Boolean);
const chromePath = chromeCandidates.find((candidate) => fs.existsSync(candidate));
if (!chromePath) {
  throw new Error("Chrome was not found; set CHROME_PATH to run the browser test");
}

function escapeHtml(value) {
  return String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}

function page(sessionId, pageId, kind, body) {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>${kind}</title></head>`
    + `<body><main data-page-kind="${kind}" data-session-id="${sessionId}" data-page-id="${pageId}">${body}</main></body></html>`;
}

function form(sessionId, pageId, content) {
  return `<form method="post" action="/dispatch"><input type="hidden" name="session_id" value="${sessionId}">`
    + `<input type="hidden" name="page_id" value="${pageId}">${content}</form>`;
}

function selection(sessionId, pageId, message = "") {
  return page(sessionId, pageId, "SELECTION", `<h1>Selection</h1>${message}`
    + form(sessionId, pageId, `<label for="P_CARR">Carrier</label><input id="P_CARR" name="P_CARR">`
      + `<button type="submit" name="gg_action" value="SUBMIT">Continue</button>`
      + `<button type="submit" name="gg_action" value="HELP:P_CARR">Help</button>`
      + `<button type="submit" name="gg_action" value="VALUE_HELP:P_CARR">Value help</button>`));
}

function list(sessionId, pageId, text = "") {
  return page(sessionId, pageId, "LIST", `<h1>List</h1><p id="result">${escapeHtml(text)}</p>`
    + form(sessionId, pageId, `<button type="submit" name="gg_action" value="LINE:1|line-token">Select line 1</button>`
      + `<button type="submit" name="gg_action" value="BACK">Back</button>`
      + `<button type="submit" name="gg_action" value="TERMINAL">Exit</button>`));
}

function dynpro(sessionId, pageId) {
  return page(sessionId, pageId, "DYNPRO", `<h1>Screen</h1>`
    + form(sessionId, pageId, `<label for="FIELD">Field</label><input id="FIELD" name="FIELD">`
      + `<button type="submit" name="gg_action" value="SUBMIT">Apply</button>`));
}

let nextSession = 0;
const sessions = new Map();
const server = createHtmlHostServer({
  start: async () => {
    const sessionId = `BROWSER-${++nextSession}`;
    sessions.set(sessionId, {pageId: 1, kind: "SELECTION"});
    return {valid: true, html: selection(sessionId, 1)};
  },
  dispatch: async (request) => {
    const state = sessions.get(request.session_id);
    if (!state || String(state.pageId) !== request.page_id) {
      return {valid: false, error: "Stale host page"};
    }
    state.pageId += 1;
    if (request.action === "HELP") {
      state.kind = "SELECTION";
      return {valid: true, html: selection(request.session_id, state.pageId, `<p role="status">Field help</p>`)};
    }
    if (request.action === "VALUE_HELP") {
      state.kind = "SELECTION";
      return {valid: true, html: selection(request.session_id, state.pageId, `<p role="status">Value help</p>`)};
    }
    if (request.action === "LINE") {
      state.kind = "DYNPRO";
      return {valid: true, html: dynpro(request.session_id, state.pageId)};
    }
    if (request.action === "BACK") {
      state.kind = "SELECTION";
      return {valid: true, html: selection(request.session_id, state.pageId)};
    }
    if (request.action === "TERMINAL") {
      state.kind = "TERMINAL";
      return {valid: true, html: page(request.session_id, state.pageId, "TERMINAL", `<h1>Finished</h1>`)};
    }
    if (request.action === "SUBMIT" && state.kind === "DYNPRO") {
      state.kind = "LIST";
      return {valid: true, html: list(request.session_id, state.pageId, `PAI: ${request.dynpro_values[0]?.value ?? ""}`)};
    }
    state.kind = "LIST";
    return {valid: true, html: list(request.session_id, state.pageId, `Carrier: ${request.values[0]?.value ?? ""}`)};
  },
});

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
const base = `http://127.0.0.1:${address.port}`;
const browser = await chromium.launch({headless: true, executablePath: chromePath});
const context = await browser.newContext();
const pageObject = await context.newPage();

try {
  await pageObject.goto(base + "/");
  await pageObject.locator("#P_CARR").fill("LH");
  await pageObject.getByRole("button", {name: "Continue"}).click();
  await pageObject.waitForLoadState("networkidle");
  assert.equal(await pageObject.locator("main").getAttribute("data-page-kind"), "LIST");
  assert.equal(await pageObject.locator("#result").textContent(), "Carrier: LH");

  await pageObject.getByRole("button", {name: "Select line 1"}).click();
  await pageObject.waitForLoadState("networkidle");
  assert.equal(await pageObject.locator("main").getAttribute("data-page-kind"), "DYNPRO");
  await pageObject.locator("#FIELD").fill("changed");
  await pageObject.getByRole("button", {name: "Apply"}).click();
  await pageObject.waitForLoadState("networkidle");
  assert.equal(await pageObject.locator("main").getAttribute("data-page-kind"), "LIST");
  assert.equal(await pageObject.locator("#result").textContent(), "PAI: changed");

  await pageObject.goto(base + "/");
  await pageObject.getByRole("button", {name: "Help", exact: true}).click();
  await pageObject.waitForLoadState("networkidle");
  assert.equal(await pageObject.locator("[role=status]").textContent(), "Field help");

  await pageObject.goto(base + "/");
  await pageObject.getByRole("button", {name: "Value help"}).click();
  await pageObject.waitForLoadState("networkidle");
  assert.equal(await pageObject.locator("[role=status]").textContent(), "Value help");

  await pageObject.goto(base + "/");
  await pageObject.getByRole("button", {name: "Continue"}).click();
  await pageObject.waitForLoadState("networkidle");
  await pageObject.getByRole("button", {name: "Back"}).click();
  await pageObject.waitForLoadState("networkidle");
  assert.equal(await pageObject.locator("main").getAttribute("data-page-kind"), "SELECTION");

  await pageObject.goto(base + "/");
  await pageObject.getByRole("button", {name: "Continue"}).click();
  await pageObject.waitForLoadState("networkidle");
  await pageObject.getByRole("button", {name: "Exit"}).click();
  await pageObject.waitForLoadState("networkidle");
  assert.equal(await pageObject.locator("main").getAttribute("data-page-kind"), "TERMINAL");
  assert.equal(await pageObject.locator("form").count(), 0);
} finally {
  await context.close();
  await browser.close();
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
}

console.log("HTML browser round trips: ok");
