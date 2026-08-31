import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_074 - displays and submits multiple-selection ranges", async ({page, host}) => {
  await openExample(page, host, 74);
  await page.getByRole("button", {name: "Value help for Flight choices"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-range-row")).toHaveCount(3);
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(3);
});
