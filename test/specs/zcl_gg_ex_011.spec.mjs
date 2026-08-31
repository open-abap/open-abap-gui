import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_011 — runs LOAD-OF-PROGRAM before selection`, async ({page, host}) => {
  await openExample(page, host, 11);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("loaded  started");
});
