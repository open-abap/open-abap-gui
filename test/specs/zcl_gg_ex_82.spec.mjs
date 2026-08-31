import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_82 - saves, overwrites, loads, and deletes a variant", async ({page, host}) => {
  await openExample(page, host, 82);
  await page.locator('[name="P_NAME"]').fill("BROWSER82");
  await page.locator('[name="P_VALUE"]').fill("one");
  await page.getByRole("button", {name: "Save"}).click();
  await page.waitForLoadState("networkidle");
  await page.locator('[name="P_VALUE"]').fill("two");
  await page.getByRole("button", {name: "Save"}).click();
  await page.waitForLoadState("networkidle");
  await page.locator('[name="P_VALUE"]').fill("");
  await page.getByRole("button", {name: "Load"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator('[name="P_VALUE"]')).toHaveValue("two");
  await page.getByRole("button", {name: "Delete"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.getByRole("alert")).toContainText("Variant deleted");
});

