import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_018 — executes a radio-button report`, async ({page, host}) => {
  await openExample(page, host, 18);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
});
