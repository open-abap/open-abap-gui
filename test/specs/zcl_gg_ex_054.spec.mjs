import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_054 — exposes SUBMIT AND RETURN`, async ({page, host}) => {
  await openExample(page, host, 54);
  await expectPageKind(page, "NAVIGATION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "SUBMIT_RETURN");
  await expect(page.getByText("Continue to ZGG_EX_020.")).toBeVisible();
  await submit(page, "Continue");
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("back");
});
