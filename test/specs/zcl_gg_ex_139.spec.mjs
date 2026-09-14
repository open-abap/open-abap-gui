import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_139 — dispatches an ALV toolbar event", async ({page, host}) => {
  await openExample(page, host, 139);
  const surface = page.locator(".gg-structured-table");
  await expect(page.locator('[data-control-kind="ALV_GRID"] table')).toHaveAttribute("data-ready-for-input", "0");
  await expect(surface).toContainText("No ALV event dispatched yet");
  await page.getByRole("button", {name: "Application toolbar event"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toContainText("event delivered");
  await surface.getByRole("button", {name: "Delayed selection"}).click();
  await page.waitForLoadState("load");
  await expect(surface).toContainText("delayed selection callback delivered");
  await surface.getByRole("button", {name: "Data changed"}).click();
  await page.waitForLoadState("load");
  await expect(surface).toContainText("data_changed and data_changed_finished delivered");
  await surface.getByRole("button", {name: "Drag/drop event"}).click();
  await page.waitForLoadState("load");
  await expect(surface).toContainText("drag/drop event delivered");
  await surface.getByRole("button", {name: "Double-click event"}).click();
  await page.waitForLoadState("load");
  await expect(surface).toContainText("double-click delivered for row 2");
});

