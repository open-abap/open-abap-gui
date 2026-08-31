import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_078 - preserves fields around value-help requests", async ({page, host}) => {
  await openExample(page, host, 78);
  await page.getByRole("button", {name: "Value help for Range"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator('[name="P_CARRIER"]')).toHaveValue("");
  await page.getByRole("button", {name: "Value help for Carrier"}).click();
  await page.waitForLoadState("networkidle");
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
