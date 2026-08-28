import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_03 — renders skips, underlines, and new lines`, async ({page, host}) => {
  await openExample(page, host, 3);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("first");
  await expect(page.locator(".gg-list")).toContainText("--------------------");
  await expect(page.locator(".gg-list")).toContainText("second");
});
