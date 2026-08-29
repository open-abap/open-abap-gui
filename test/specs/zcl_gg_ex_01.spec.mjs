import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_01 — renders a literal list field`, async ({page, host}) => {
  await openExample(page, host, 1);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(1);
  await expect(page.locator(".gg-list")).toContainText("hello world");
});
