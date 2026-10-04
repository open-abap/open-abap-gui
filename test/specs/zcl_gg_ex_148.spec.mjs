import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_148 — draws a bar chart from the chart data", async ({page, host}) => {
  await openExample(page, host, 148);
  const chart = page.locator('[data-control-kind="CHART_ENGINE"] .gg-chart');
  await expect(chart).toHaveAttribute("data-chart-type", "Bars");
  await expect(chart.getByRole("img", {name: "Occupied seats per airline"}).locator("rect")).toHaveCount(3);
  await expect(chart.locator(".gg-chart-data")).toContainText("United Airlines");
  await expect(chart.locator(".gg-chart-data")).toContainText("420");
  await submit(page, "Columns");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Chart type Columns");
  await expect(chart).toHaveAttribute("data-chart-type", "Columns");
});
