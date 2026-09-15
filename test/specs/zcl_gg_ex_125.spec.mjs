import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_125 — renders enabled and disabled toolbar buttons", async ({page, host}) => {
  await openExample(page, host, 125);
  const toolbar = page.locator('.gg-control-toolbar');
  await expect(toolbar.getByRole("button", {name: "Run"})).toBeEnabled();
  await expect(toolbar.getByRole("button", {name: "Disabled"})).toBeDisabled();
  await expect(toolbar.locator(".gg-toolbar-overflow")).toHaveCount(1);
  await expect(toolbar.getByRole("button", {name: "Toggle"})).toHaveAttribute("aria-pressed", "true");
  await expect(toolbar.locator('[role="menu"]')).toContainText("Menu action");
});

test("ZCL_GG_EX_125 — dispatches a control-toolbar toggle through the host", async ({page, host}) => {
  await openExample(page, host, 125);
  await page.locator('.gg-control-toolbar').getByRole("button", {name: "Toggle"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toHaveText("toolbar toggle state dispatched by the server");
});

