import {test, expect, openExample, expectPageKind, expectWorkbench} from "../fixtures.mjs";

test("ZCL_GG_EX_162 — renders an ALV grid created on the default screen", async ({page, host}) => {
  await openExample(page, host, 162);
  await expectPageKind(page, "DYNPRO");
  await expect(page.getByRole("heading", {name: "Paused events"})).toBeVisible();
  const grid = page.locator('[data-control-kind="ALV_GRID"]');
  await expect(grid).toHaveCount(1);
  await expect(grid.locator("table th")).toContainText(["Select", "Event", "Object", "Paused by"]);
  await expect(grid.locator("tbody tr")).toHaveCount(2);
  await page.locator(".wb-toolbar").getByRole("button", {name: "Refresh"}).click();
  await page.waitForLoadState("load");
  await expect(grid).toHaveCount(1);
  await expect(grid.locator("tbody tr")).toHaveCount(2);
});

test("ZCL_GG_EX_162 — Back leaves the screen", async ({page, host}) => {
  await openExample(page, host, 162);
  await page.getByRole("button", {name: "Back", exact: true}).click();
  await page.waitForLoadState("load");
  await expectWorkbench(page);
});
