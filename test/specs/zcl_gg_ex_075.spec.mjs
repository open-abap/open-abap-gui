import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_075 - retains values while switching tabs", async ({page, host}) => {
  await openExample(page, host, 75);
  await page.locator('[name="P_GENERAL"]').fill("general");
  await page.locator('[name="P_DETAILS"]').fill("details");
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await page.getByRole("tab", {name: "Details"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("tab", {name: "Details"})).toHaveAttribute("aria-selected", "true");
  await expect(page.locator('[name="P_GENERAL"]')).toHaveValue("general");
  await expect(page.locator('[name="P_DETAILS"]')).toHaveValue("details");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["general", "details"]);
});
