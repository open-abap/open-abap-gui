import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_021 — executes a selection-screen layout report`, async ({page, host}) => {
  await openExample(page, host, 21);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
});
