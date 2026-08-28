import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_09 — renders TOP-OF-PAGE before the body`, async ({page, host}) => {
  await openExample(page, host, 9);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("header");
  await expect(page.locator(".gg-list")).toContainText("body");
});
