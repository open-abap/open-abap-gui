import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_147 — reports SALV selections and events", async ({page, host}) => {
  await openExample(page, host, 147);
  await page.getByLabel("Select row 1").check();
  await page.getByLabel("Select row 3").check();
  await submit(page, "Show selection");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("2 flight(s) selected");
  await page.locator('[data-control-kind="ALV_GRID"]').locator("button.gg-alv-hotspot").first().click();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Airline LH chosen");
  await page.locator('[data-control-kind="ALV_GRID"]').locator('tbody td[data-fieldname="SEATSOCC"]').nth(1).dblclick();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Double click on UA 0941, column SEATSOCC");
});
