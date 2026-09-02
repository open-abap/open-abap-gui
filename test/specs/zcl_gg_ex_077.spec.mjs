import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_077 - executes distinct selection function keys", async ({page, host}) => {
  await openExample(page, host, 77);
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await page.getByRole("button", {name: "Beta action"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[name="P_ACTION"]')).toHaveValue("beta");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("beta");
});
