import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_028 — executes selection-screen output mutation`, async ({page, host}) => {
  await openExample(page, host, 28);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
});
