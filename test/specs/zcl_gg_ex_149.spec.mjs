import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_149 — draws two series as lines or columns", async ({page, host}) => {
  await openExample(page, host, 149);
  const chart = page.locator('[data-control-kind="CHART_ENGINE"] .gg-chart');
  await expect(chart).toHaveAttribute("data-chart-type", "Lines");
  await expect(chart.locator("polyline")).toHaveCount(2);
  await expect(chart.locator(".gg-chart-legend li")).toHaveText(["Capacity", "Occupied"]);
  await submit(page, "Columns");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("4 months, chart type Columns");
  await expect(chart.locator("rect")).toHaveCount(8);
});
