import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_043 — round-trips HIDE values on line selection`, async ({page, host}) => {
  await openExample(page, host, 43);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(3);
  await submit(page, "Select line 2");
  // AT LINE-SELECTION writes the detail list, which replaces the basic list.
  await expect(page.locator(".gg-list-line")).toHaveText(["2"]);
});
