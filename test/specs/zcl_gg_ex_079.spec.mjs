import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_079 - associates contextual help with its field", async ({page, host}) => {
  await openExample(page, host, 79);
  await page.getByRole("button", {name: "Field help for Field with help"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator("#gg-help-text")).toContainText("business key");
  await expect(page.locator('[name="P_HELP"]')).toHaveAttribute("aria-describedby", "gg-help-text");
  await page.locator('[name="P_HELP"]').fill("entered");
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
});
