import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_55 — exposes list-to-memory submission`, async ({page, host}) => {
  await openExample(page, host, 55);
  await expectPageKind(page, "NAVIGATION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "SUBMIT_RETURN");
  await expect(page.getByText("Continue to ZGG_EX_01.")).toBeVisible();
});
