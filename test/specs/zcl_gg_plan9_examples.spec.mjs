import {test, expect, openExample} from "../fixtures.mjs";

async function pressToolbar(page, label) {
  await page.locator(".wb-toolbar").getByRole("button", {name: label}).click();
  await page.waitForLoadState("load");
}

test("ZCL_GG_EX_152 - timer lifecycle is deterministic", async ({page, host}) => {
  await openExample(page, host, 152);
  await expect(page.locator(".gg-list-status")).toHaveText("TIMER STOPPED");
  await expect(page.locator(".gg-structured-table")).toContainText("deterministic clock");
  await pressToolbar(page, "Start timer");
  await expect(page.locator(".gg-list-status")).toHaveText("TIMER RUNNING");
  await pressToolbar(page, "Tick once");
  await expect(page.locator(".gg-structured-table")).toContainText("Completed ticks");
  await pressToolbar(page, "Stop timer");
  await expect(page.locator(".gg-list-status")).toHaveText("TIMER STOPPED");
});

test("ZCL_GG_EX_153 - tree and grid expose typed drop actions", async ({page, host}) => {
  await openExample(page, host, 153);
  await expect(page.getByRole("tree", {name: "Drag source tree"})).toBeVisible();
  await expect(page.locator("[data-node-key=NODE-100]")).toHaveAttribute("aria-selected", "true");
  await pressToolbar(page, "Copy node");
  await expect(page.locator(".gg-structured-table")).toContainText("Grid row 2 (copy)");
  await pressToolbar(page, "Undo drop");
  await expect(page.locator(".gg-structured-table")).toContainText("Source row 1");
});

test("ZCL_GG_EX_154 - frontend services report capability boundaries", async ({page, host}) => {
  await openExample(page, host, 154);
  await expect(page.locator('input[type="file"]')).toHaveCount(1);
  await pressToolbar(page, "Directory capability");
  await expect(page.locator(".gg-structured-table")).toContainText("desktop API unavailable");
  await expect(page.locator(".gg-list-line")).toContainText("refused");
});

test("ZCL_GG_EX_155 - modeless dialog keeps the parent available", async ({page, host}) => {
  await openExample(page, host, 155);
  await expect(page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]')).toHaveCount(1);
  await pressToolbar(page, "Resize dialog");
  await expect(page.locator(".gg-structured-table")).toContainText("380 x 190");
  await pressToolbar(page, "Parent action");
  await expect(page.locator(".gg-list-line")).toContainText("parent action remained available");
});

test("ZCL_GG_EX_156 - popup actions return typed state", async ({page, host}) => {
  await openExample(page, host, 156);
  await pressToolbar(page, "Input popup");
  await expect(page.getByRole("dialog", {name: "INPUT popup"})).toBeVisible();
  await page.getByRole("dialog", {name: "INPUT popup"}).getByRole("button", {name: "OK"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("article", {name: "Popup compatibility gallery"})).toContainText("INPUT returned typed OK");
});

test("ZCL_GG_EX_157 - variant lifecycle stays report-local", async ({page, host}) => {
  await openExample(page, host, 157);
  await pressToolbar(page, "Save layout");
  await expect(page.locator(".gg-list-status")).toContainText("SAVED");
  await expect(page.locator(".gg-structured-table")).toContainText("saved");
  await pressToolbar(page, "Cleanup layouts");
  await expect(page.locator(".gg-list-status")).toHaveText("ALV LAYOUT READY");
});

test("ZCL_GG_EX_158 - SALV fallback preserves header item structure", async ({page, host}) => {
  await openExample(page, host, 158);
  const table = page.locator(".gg-structured-table");
  await expect(table).toContainText("Order 100");
  await expect(table).toContainText("LH400 / Lufthansa");
  await expect(table).toContainText("Total: 410.00");
  await pressToolbar(page, "Select item");
  await expect(page.locator(".gg-list-line")).toContainText("Selected item LH400");
});

test("ZCL_GG_EX_159 - calendar renders nine stable months", async ({page, host}) => {
  await openExample(page, host, 159);
  const table = page.locator(".gg-structured-table");
  await expect(table.locator("tbody tr")).toHaveCount(9);
  await expect(table).toContainText("ISO weeks");
  await pressToolbar(page, "Next months");
  await expect(table).toContainText("2026-11");
  await pressToolbar(page, "Previous months");
  await expect(table).toContainText("2026-08");
});
