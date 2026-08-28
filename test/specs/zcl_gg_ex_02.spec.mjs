import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_02 — preserves positioned and no-gap fields`, async ({page, host}) => {
  await openExample(page, host, 2);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line").first()).toContainText("abcde xy");
  await expect(page.locator(".gg-list-line .gg-list-fragment")).toHaveCount(3);
});
