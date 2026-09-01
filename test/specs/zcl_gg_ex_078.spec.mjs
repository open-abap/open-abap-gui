import {test, expect, openExample, dispatch, submit, expectPageKind, clickHelp} from "../fixtures.mjs";

test("ZCL_GG_EX_078 - preserves fields around value-help requests", async ({page, host}) => {
  await openExample(page, host, 78);
  await clickHelp(page, "S_RANGE-LOW", "Value help for Range");
  await page.waitForLoadState("load");
  await expect(page.locator('[name="P_CARRIER"]')).toHaveValue("");
  await clickHelp(page, "P_CARRIER", "Value help for Carrier");
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-value-help li")).toHaveCount(3);
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_CARRIER", value: "LH"},
      {name: "S_RANGE", ranges: [{sign: "I", option: "EQ", low: "AA"}]},
      {name: "P_REQUIRED", value: "ok"},
    ],
  });
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["LH", "AA"]);
});

test("ZCL_GG_EX_078 - F4 reaches the value help of a selection field and of a range row", async ({page, host}) => {
  await openExample(page, host, 78);
  await page.locator('[name="P_CARRIER"]').focus();
  await page.keyboard.press("F4");
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-value-help li")).toHaveCount(3);

  await openExample(page, host, 78);
  await page.locator('[name="S_RANGE-LOW"]').focus();
  await page.keyboard.press("F4");
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-range-row")).toHaveCount(3);
  await expect(page.locator('[name="S_RANGE-1-LOW"]')).toHaveValue("AA");
});
