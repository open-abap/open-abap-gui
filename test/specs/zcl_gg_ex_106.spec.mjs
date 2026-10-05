import {test, expect, openExample} from "../fixtures.mjs";

const cell = (page, column, row) =>
  page.locator(`[name="gg-cell-TC_FLIGHTS-${column}-${row}"]`);

test("ZCL_GG_EX_106 — edits table control lines and reads them back in PAI", async ({page, host}) => {
  await openExample(page, host, 106);
  await expect(cell(page, "CITYFROM", 2)).toHaveValue("Frankfurt");
  // Only the lines the table has are ready for input.
  await expect(cell(page, "CITYFROM", 4)).toBeDisabled();

  await cell(page, "CITYTO", 2).fill("Chicago");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Save"}).last().click();
  await page.waitForLoadState("load");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Saved; LH 0400 flies Frankfurt - Chicago");
  await expect(cell(page, "CITYTO", 2)).toHaveValue("Chicago");
});

test("ZCL_GG_EX_106 — a CHAIN in the table loop checks each changed line", async ({page, host}) => {
  await openExample(page, host, 106);
  await cell(page, "CITYTO", 3).fill("Frankfurt");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Save"}).last().click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("alert")).toContainText("Flight UA 0941 cannot end where it starts");
});
