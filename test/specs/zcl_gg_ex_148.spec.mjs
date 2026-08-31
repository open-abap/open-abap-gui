import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_148 — exposes an accessible bar chart fallback", async ({page, host}) => {
  await openExample(page, host, 148);
  await expect(page.locator('[data-control-kind="BARCHART"]')).toHaveCount(1);
  await expect(page.locator(".gg-chart-fallback table")).toContainText("Lufthansa");
  await expect(page.locator(".gg-chart-fallback table")).toContainText("42");
});

