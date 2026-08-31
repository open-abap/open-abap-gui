import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_109 — changes the active tab screen", async ({page, host}) => {
  await openExample(page, host, 109);
  await page.getByRole("tab", {name: "Two"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator('[data-screen="0300"]')).toHaveCount(1);
  await expect(page.locator('[name="P_TAB_TWO"]')).toHaveValue("two");
});

