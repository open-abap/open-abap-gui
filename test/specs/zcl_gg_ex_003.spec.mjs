import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_003 — renders skips, underlines, and new lines`, async ({page, host}) => {
  await openExample(page, host, 3);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(5);
  await expect(page.locator(".gg-list-line").nth(0)).toHaveText("first");
  await expect(page.locator(".gg-list-line").nth(3)).toHaveText("--------------------");
  await expect(page.locator(".gg-list-line").nth(4)).toContainText("second");
});
