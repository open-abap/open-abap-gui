import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_149 — preserves chart engine payload intent", async ({page, host}) => {
  await openExample(page, host, 149);
  await expect(page.locator('[data-control-kind="CHART_ENGINE"]')).toContainText("Chart data");
  await expect(page.locator('[data-chart-payload="series=flights"]')).toContainText("server-side");
  await expect(page.locator(".gg-chart-fallback table")).toContainText("August");
});

