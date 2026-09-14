import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_135 — renders ALV field-catalog columns", async ({page, host}) => {
  await openExample(page, host, 135);
  await expect(page.locator('[data-control-kind="ALV_GRID"] table th')).toContainText(["Select", "Carrier", "Flight", "Seats"]);
  await expect(page.locator('[data-control-kind="ALV_GRID"] tbody tr')).toHaveCount(3);
  await expect(page.locator('[data-control-kind="ALV_GRID"] table')).toHaveAttribute("data-field-count", "3");
  await expect(page.locator('[data-control-kind="ALV_GRID"] tbody [data-fieldname="CARRIER"]').first()).toHaveAttribute("data-emphasize", "C310");
  await expect(page.locator('[data-control-kind="ALV_GRID"] .gg-alv-icon').first()).toHaveText("LH400");
  await expect(page.locator('[data-control-kind="ALV_GRID"] tfoot .gg-grid-total')).toContainText("550");
  const metadata = page.locator('.gg-structured-table[aria-label="Runtime ALV structure"]');
  await expect(metadata).toContainText("ZGG_DYNAMIC_FLIGHT_ROW");
  const formats = page.locator('.gg-structured-table[aria-label="ALV presentation formats"]');
  await expect(formats.locator("tr[data-row-color='C310']")).toHaveAttribute("data-row-style", "emphasis");
  await expect(formats.locator("td[data-cell-style='currency']").first()).toHaveAttribute("data-cell-color", "C210");
  await expect(formats).toContainText("traffic lights");
  await formats.getByRole("button", {name: "Inspect row 1"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toContainText("Dynamic structure");
  await metadata.getByRole("button", {name: "Toggle generated style"}).click();
  await page.waitForLoadState("load");
  await expect(metadata).toContainText("STYLE");
  await metadata.getByRole("button", {name: "Append runtime row"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-control-kind="ALV_GRID"] tbody tr')).toHaveCount(4);
  await metadata.getByRole("button", {name: "Inspect structure"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toContainText("Dynamic structure");
});

