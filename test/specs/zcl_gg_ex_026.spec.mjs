import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_026 — executes a tabbed selection report`, async ({page, host}) => {
  await openExample(page, host, 26);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_NAME"]')).toHaveValue("Ada Lovelace");
  await page.locator('[name="P_CITY"]').fill("Paris");
  await page.getByRole("tab", {name: "Details"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("tab", {name: "Details"})).toHaveAttribute("aria-selected", "true");
  await page.locator('[name="P_COUNT"]').fill("7");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["Name: Ada Lovelace", "City: Paris", "Count: 7", "Active"]);
});
