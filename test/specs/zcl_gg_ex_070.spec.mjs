import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_070 — switches radio-driven blocks and validation", async ({page, host}) => {
  await openExample(page, host, 70);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_ALLV"]')).toBeVisible();
  await expect(page.locator('[name="P_ONEV"]')).toBeHidden();
  await page.locator('[name="P_REQ"]').fill("ready");
  await Promise.all([
    page.waitForNavigation({waitUntil: "load"}),
    page.locator('[name="gg-radio-G1"][value="P_ONE"]').check(),
  ]);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_ALLV"]')).toBeHidden();
  await expect(page.locator('[name="P_ONEV"]')).toBeVisible();
  await submit(page);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("Enter a value for one flight");
  await page.locator('[name="P_ONEV"]').fill("one");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("one");
});
