import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_048 — renders the parent list for nested selection`, async ({page, host}) => {
  await openExample(page, host, 48);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("row");
});
