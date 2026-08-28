import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_44 — renders PF-STATUS and excluded commands`, async ({page, host}) => {
  await openExample(page, host, 44);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-status")).toContainText("LIST");
  await expect(page.locator(".gg-list")).toContainText("body");
});
