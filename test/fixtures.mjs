import {test as base, expect} from "playwright/test";
import {spawn} from "node:child_process";
import {once} from "node:events";

const HOST_STARTUP_TIMEOUT_MS = 30_000;

async function stopHost(child) {
  if (child.exitCode === null) {
    child.kill();
    await once(child, "close");
  }
}

async function startHost() {
  const child = spawn(process.execPath, ["test/start-server.mjs"], {
    cwd: process.cwd(),
    env: {...process.env, OPEN_ABAP_GUI_PORT: "0"},
    stdio: ["ignore", "pipe", "pipe"],
  });
  const started = new Promise((resolve, reject) => {
    let settled = false;
    let stdout = "";
    let stderr = "";
    const timeout = setTimeout(() => {
      if (settled) return;
      settled = true;
      reject(new Error("Timed out starting the ABAP HTML host"));
    }, HOST_STARTUP_TIMEOUT_MS);
    const finish = (callback) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      callback();
    };
    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
      const match = stdout.match(/ABAP HTML server started at (http:\/\/127\.0\.0\.1:\d+)/);
      if (match) finish(() => resolve(match[1]));
    });
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.once("error", (error) => {
      finish(() => reject(new Error(`Unable to start the ABAP HTML host: ${error.message}`)));
    });
    child.once("exit", (code) => {
      const details = stderr.trim() || stdout.trim();
      finish(() => reject(new Error(
        `ABAP HTML host exited during startup (${code})${details ? `: ${details}` : ""}`)));
    });
  });
  try {
    const baseUrl = await started;
    return {child, baseUrl};
  } catch (error) {
    await stopHost(child);
    throw error;
  }
}

export const test = base.extend({
  host: [async ({}, use) => {
    const {child, baseUrl} = await startHost();

    try {
      await use({baseUrl});
    } finally {
      await stopHost(child);
    }
  }, {scope: "worker"}],
});

export {expect};

export async function openExample(page, host, number) {
  const id = String(number).padStart(3, "0");
  const response = await page.goto(`${host.baseUrl}/ZCL_GG_EX_${id}`);
  expect(response?.status()).toBe(200);
  await expect(page.locator("[data-page-kind]")).toHaveCount(1);
}

// Search help bubbles are revealed only while their field has focus, so a test
// has to put the cursor in the field before it can press the bubble.
export async function clickHelp(page, fieldName, helpName) {
  await page.locator(`[name="${fieldName}"]`).first().focus();
  await page.getByRole("button", {name: helpName}).click();
}

export async function submit(page, buttonName = "Execute") {
  await page.getByRole("button", {name: buttonName}).click();
  await page.waitForLoadState("load");
}

export async function dispatch(page, request) {
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const response = await page.context().request.post(
    new URL("/dispatch", page.url()).href,
    {
      headers: {"content-type": "application/json"},
      data: {session_id: sessionId, page_id: pageId, ...request},
    });
  const html = await response.text();
  expect(response.status(), html).toBe(200);
  await page.setContent(html, {waitUntil: "load"});
  await expect(page.locator("[data-page-kind]")).toHaveCount(1);
}

export function expectPageKind(page, kind) {
  return expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", kind);
}
