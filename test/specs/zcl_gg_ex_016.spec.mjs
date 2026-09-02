import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_016 — renders and submits a required parameter`, async ({page, host}) => {
  await openExample(page, host, 16);
  // The screen opens clean; the obligatory field is only rejected once the
  // user actually asks to execute with it empty.
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toHaveCount(0);
  await submit(page);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("P_NAME");
  await expect(page.locator('[name="P_NAME"]')).toHaveAttribute("aria-invalid", "true");
  await page.locator('[name="P_NAME"]').fill("Ada");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("Ada");
});
