import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_026 — executes a tabbed selection report`, async ({page, host}) => {
  await openExample(page, host, 26);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
});
