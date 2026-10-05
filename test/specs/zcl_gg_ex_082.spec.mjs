import {test, expect, openExample, expectPageKind, statusMessage} from "../fixtures.mjs";

test("ZCL_GG_EX_082 - saves, overwrites, loads, and deletes a variant", async ({page, host}) => {
  await openExample(page, host, 82);
  await page.locator('[name="P_NAME"]').fill("BROWSER82");
  await page.locator('[name="P_VALUE"]').fill("one");
  await page.locator("#gg-main-content").getByRole("button", {name: "Save"}).click();
  await page.waitForLoadState("load");
  await expect(statusMessage(page)).toContainText("Variant saved");
  await page.locator('[name="P_VALUE"]').fill("two");
  await page.locator("#gg-main-content").getByRole("button", {name: "Save"}).click();
  await page.waitForLoadState("load");
  await page.locator('[name="P_VALUE"]').fill("");
  await page.getByRole("button", {name: "Load"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[name="P_VALUE"]')).toHaveValue("two");
  await page.getByRole("button", {name: "Delete"}).click();
  await page.waitForLoadState("load");
  await expectPageKind(page, "SELECTION");
  await expect(statusMessage(page)).toContainText("Variant deleted");
  await page.getByRole("button", {name: "Load"}).click();
  await page.waitForLoadState("load");
  await expect(statusMessage(page)).toContainText("Variant not found");
});
