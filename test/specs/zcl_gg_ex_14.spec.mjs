import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_14 — exposes STOP as a navigation state`, async ({page, host}) => {
  await openExample(page, host, 14);
  await expectPageKind(page, "NAVIGATION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "STOP");
  await expect(page.locator(".gg-list")).toHaveCount(0);
});
