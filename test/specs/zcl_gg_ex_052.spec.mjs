import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_052 — resumes after CALL SCREEN`, async ({page, host}) => {
  await openExample(page, host, 52);
  await expectPageKind(page, "NAVIGATION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "CALL_SCREEN");
  await expect(page.getByText("Continue to 0100.")).toBeVisible();
  await submit(page, "Continue");
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("back");
});
