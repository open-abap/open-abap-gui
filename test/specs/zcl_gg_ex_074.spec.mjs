import {test, expect, openExample, dispatch, submit, expectPageKind, clickHelp} from "../fixtures.mjs";

test("ZCL_GG_EX_074 - displays and submits multiple-selection ranges", async ({page, host}) => {
  await openExample(page, host, 74);
  await clickHelp(page, "S_MULTI-LOW", "Value help for Flight choices");
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-range-row")).toHaveCount(3);
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(3);
});
