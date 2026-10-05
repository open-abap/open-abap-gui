import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_139 — raises the grid's toolbar, hotspot and double-click events", async ({page, host}) => {
  await openExample(page, host, 139);
  await submit(page, "Details");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Select a flight first");
  await page.getByLabel("Select row 2").check();
  await submit(page, "Details");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Details of UA 0941: 210 seats");
  await page.locator('[data-control-kind="ALV_GRID"]').locator("button.gg-alv-hotspot").first().click();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Airline LH chosen");
  await page.locator('[data-control-kind="ALV_GRID"]').locator('tbody td[data-fieldname="SEATSOCC"]').first().dblclick();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Double click on LH 0400, column SEATSOCC");
});
