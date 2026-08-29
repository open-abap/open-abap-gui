import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_33 — reports a block validation error and retries`, async ({page, host}) => {
  await openExample(page, host, 33);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("fill one of the two");
  await page.locator('[name="P_A"]').fill("A");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await expect(page.getByRole("alert")).toHaveCount(0);
});
