import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_136 — accepts editable ALV data", async ({page, host}) => {
  await openExample(page, host, 136);
  const grid = page.locator('[data-control-kind="ALV_GRID"]');
  await expect(grid.locator("table")).toHaveAttribute("data-ready-for-input", "1");
  await expect(grid.locator('tbody td[data-fieldname="CARRIER"]').first()).toHaveAttribute("data-f4", "true");
  await expect(grid.locator('select[aria-label="FLIGHT row 1"]')).toHaveCount(1);
  await expect(grid.locator('input[type="checkbox"][aria-label="ACTIVE row 1"]')).toHaveCount(1);
  await expect(grid.getByRole("button", {name: "Inspect"}).first()).toBeVisible();
  await expect(page.getByLabel("Seats for LH400")).toHaveValue("180");
  const surface = page.locator(".gg-structured-table");
  await surface.locator('[name="ALV-SEATS"]').fill("0");
  await surface.getByRole("button", {name: "Validate changes"}).click();
  await page.waitForLoadState("load");
  await expect(surface).toContainText("Draft rejected");
  await surface.locator('[name="ALV-SEATS"]').fill("240");
  await page.getByRole("button", {name: "Save changed data"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toContainText("changed data accepted");
  await expect(page.locator(".gg-structured-table")).toContainText("240 seats");
  await page.locator(".gg-structured-table").getByRole("button", {name: "Append row"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-control-kind="ALV_GRID"] tbody tr')).toHaveCount(4);
  await page.locator(".gg-structured-table").getByRole("button", {name: "Discard draft"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByLabel("Seats for LH400")).toHaveValue("240");
});

