import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_016 — renders and submits a required parameter`, async ({page, host}) => {
  await openExample(page, host, 16);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("P_NAME");
  await expect(page.locator('[name="P_NAME"]')).toHaveAttribute("aria-invalid", "true");
  await page.locator('[name="P_NAME"]').fill("Ada");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("Ada");
});
