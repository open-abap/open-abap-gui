import {test as base, expect} from "playwright/test";
import {spawn} from "node:child_process";
import {createServer} from "node:net";
import {once} from "node:events";

async function freePort() {
  const probe = createServer();
  await new Promise((resolve) => probe.listen(0, "127.0.0.1", resolve));
  const port = probe.address().port;
  await new Promise((resolve, reject) => probe.close((error) => error ? reject(error) : resolve()));
  return port;
}

async function startHost() {
  const port = await freePort();
  const child = spawn(process.execPath, ["test/start-server.mjs"], {
    cwd: process.cwd(),
    env: {...process.env, OPEN_ABAP_GUI_PORT: String(port)},
    stdio: ["ignore", "pipe", "pipe"],
  });
  const baseUrl = `http://127.0.0.1:${port}`;
  const started = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error("Timed out starting the ABAP HTML host")), 10000);
    const check = async () => {
      try {
        const response = await fetch(baseUrl);
        if (response.ok) {
          clearTimeout(timeout);
          resolve();
          return;
        }
      } catch {
        // The child is still starting.
      }
      setTimeout(check, 50);
    };
    child.once("exit", (code) => reject(new Error(`ABAP HTML host exited during startup (${code})`)));
    check();
  });
  await started;
  return {child, baseUrl};
}

export const test = base.extend({
  host: [async ({}, use) => {
    const {child, baseUrl} = await startHost();

    try {
      await use({baseUrl});
    } finally {
      child.kill();
      await once(child, "close");
    }
  }, {scope: "worker"}],
});

export {expect};

export async function openExample(page, host, number) {
  const id = String(number).padStart(2, "0");
  const response = await page.goto(`${host.baseUrl}/ZCL_GG_EX_${id}`);
  expect(response?.status()).toBe(200);
  await expect(page.locator("[data-page-kind]")).toHaveCount(1);
}

export async function submit(page, buttonName = "Continue") {
  await page.getByRole("button", {name: buttonName}).click();
  await page.waitForLoadState("networkidle");
}

export function expectPageKind(page, kind) {
  return expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", kind);
}
