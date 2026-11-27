import {test, expect} from "playwright/test";
import {startHost, stopHost} from "../fixtures.mjs";

// Served below a path, as an ICF node serves it on a system, the shell, its
// pages and every request they send stay below that path.
const BASE = "/mount/gui";

let running;
test.beforeAll(async () => {
  running = await startHost(undefined, {OPEN_ABAP_GUI_BASE: BASE});
});
test.afterAll(async () => {
  if (running?.child) await stopHost(running.child);
});

function onScreen(page) {
  return page.frameLocator("#gg-frames iframe:not([hidden])");
}

test("the shell runs a transaction below the path it is served at", async ({page}) => {
  const paths = [];
  page.on("request", (request) => {
    const url = new URL(request.url());
    if (url.origin === new URL(running.baseUrl).origin) paths.push(url.pathname);
  });

  await page.goto(`${running.baseUrl}${BASE}/`, {waitUntil: "load"});
  await expect(onScreen(page).locator("#wb-app-panel")).toBeVisible({timeout: 30000});

  const field = onScreen(page).getByRole("textbox", {name: "Command"});
  await field.fill("/nSE16");
  await field.press("Enter");
  await expect(page.locator("#gg-rail .gg-rail-item").first().locator(".gg-rail-code")).toHaveText("SE16");
  await onScreen(page).getByRole("button", {name: "Table Contents", exact: true}).click();
  await expect(onScreen(page).locator('[data-screen="0150"]')).toHaveCount(1);

  expect(paths.length).toBeGreaterThan(2);
  expect(paths.filter((path) => !path.startsWith(`${BASE}/`))).toEqual([]);
});
