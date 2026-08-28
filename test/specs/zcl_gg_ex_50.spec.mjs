import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_50 — renders list-processing output`, async ({page, host}) => {
  await openExample(page, host, 50);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("inside the list processor");
});
