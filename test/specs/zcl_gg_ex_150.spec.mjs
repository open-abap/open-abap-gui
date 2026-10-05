import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_150 — shows the selected airline's flights in a grid and a chart", async ({page, host}) => {
  await openExample(page, host, 150);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_CARR"]')).toHaveValue("LH");
  await submit(page);
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("2 flight(s) of LH from 2026-08-01");
  await expect(page.locator('[data-control-kind="SPLITTER_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("tbody tr")).toHaveCount(2);
  await expect(page.locator('[data-control-kind="CHART_ENGINE"] .gg-chart-data')).toContainText("85");
  await page.locator('[data-control-kind="ALV_GRID"]').locator('tbody td[data-fieldname="SEATSOCC"]').first().dblclick();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("LH 0400: 180 of 280 seats");
});

test("ZCL_GG_EX_150 — selects another airline", async ({page, host}) => {
  await openExample(page, host, 150);
  await page.locator('[name="P_CARR"]').fill("UA");
  await submit(page);
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("2 flight(s) of UA from 2026-08-01");
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("tbody")).toContainText("0945");
});
