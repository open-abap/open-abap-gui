import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_15 — applies a parameter default`, async ({page, host}) => {
  await openExample(page, host, 15);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("LH");
});
