import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_17 — applies a checkbox default`, async ({page, host}) => {
  await openExample(page, host, 17);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("X");
});
