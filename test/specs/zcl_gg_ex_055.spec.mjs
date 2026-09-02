import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_055 — exposes list-to-memory submission`, async ({page, host}) => {
  await openExample(page, host, 55);
  await expectPageKind(page, "NAVIGATION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "SUBMIT_RETURN");
  await expect(page.getByText("Continue to ZGG_EX_001.")).toBeVisible();
  await submit(page, "Continue");
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("hello world");
});
