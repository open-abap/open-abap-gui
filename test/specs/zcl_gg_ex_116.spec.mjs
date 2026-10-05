import {test, expect, openExample, submit, clickHelp} from "../fixtures.mjs";

const cell = (page, column, row) => page.locator(`[name="gg-cell-TC_FLIGHTS-${column}-${row}"]`);

test("ZCL_GG_EX_116 — the airline is checked before the editor opens", async ({page, host}) => {
  await openExample(page, host, 116);
  await page.locator('[name="GV_CARRID"]').fill("XX");
  await submit(page, "Edit flights");
  await expect(page.getByRole("alert")).toContainText("Airline XX does not exist");
  await expect(page.locator('[data-screen="0100"]')).toHaveAttribute("data-cursor-field", "GV_CARRID");
});

test("ZCL_GG_EX_116 — F4 offers the airlines", async ({page, host}) => {
  await openExample(page, host, 116);
  await clickHelp(page, "GV_CARRID", "Value help for GV_CARRID");
  await page.waitForLoadState("load");
  const help = page.getByRole("region", {name: "Value help"});
  await expect(help).toContainText("United Airlines");
  await help.locator('li[data-value="UA"]').dblclick();
  await expect(page.locator('[name="GV_CARRID"]')).toHaveValue("UA");
});

test("ZCL_GG_EX_116 — edits the flights of the airline and saves them", async ({page, host}) => {
  await openExample(page, host, 116);
  await submit(page, "Edit flights");
  await expect(page.getByRole("heading", {name: "Flights of LH"})).toBeVisible();
  // Only the lines of tc_flights-lines are ready for input.
  await expect(cell(page, "CITYTO", 2)).toBeEditable();
  await expect(cell(page, "CITYTO", 3)).not.toBeEditable();
  await cell(page, "CITYTO", 2).fill("Boston");
  await page.locator(".wb-commandbar").getByRole("button", {name: "Save"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("alert")).toContainText("2 flights of LH saved");

  await submit(page, "Back");
  await expect(page.getByRole("heading", {name: "Airline"})).toBeVisible();
  await submit(page, "Edit flights");
  await expect(cell(page, "CITYTO", 2)).toHaveValue("Boston");
});
