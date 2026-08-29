import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_56 — exposes CALL TRANSACTION`, async ({page, host}) => {
  await openExample(page, host, 56);
  await expectPageKind(page, "NAVIGATION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "CALL_TRANSACTION");
  await expect(page.getByText("Continue to SE38.")).toBeVisible();
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("back");
});
