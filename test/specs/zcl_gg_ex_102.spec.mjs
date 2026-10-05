import {test, expect, openExample, clickHelp} from "../fixtures.mjs";

test("ZCL_GG_EX_102 — PROCESS ON VALUE-REQUEST offers the program's values", async ({page, host}) => {
  await openExample(page, host, 102);
  await clickHelp(page, "GV_CARRID", "Value help for GV_CARRID");
  await page.waitForLoadState("load");
  const help = page.getByRole("region", {name: "Value help"});
  await expect(help).toContainText("Lufthansa");
  await help.locator('li[data-value="LH"]').dblclick();
  await expect(page.locator('[name="GV_CARRID"]')).toHaveValue("LH");
});

test("ZCL_GG_EX_102 — F4 opens the value help of the focused field", async ({page, host}) => {
  await openExample(page, host, 102);
  await page.locator('[name="GV_CARRID"]').focus();
  await page.keyboard.press("F4");
  await page.waitForLoadState("load");
  await expect(page.getByRole("region", {name: "Value help"})).toContainText("American Airlines");
});

test("ZCL_GG_EX_102 — PROCESS ON HELP-REQUEST shows the program's help", async ({page, host}) => {
  await openExample(page, host, 102);
  await page.locator('[name="GV_CARRID"]').focus();
  await page.keyboard.press("F1");
  await page.waitForLoadState("load");
  const popup = page.getByRole("dialog", {name: "Airline"});
  await expect(popup).toContainText("for example LH for Lufthansa.");
});
