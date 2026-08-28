import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_46 — renders the line used by READ and MODIFY LINE`, async ({page, host}) => {
  await openExample(page, host, 46);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("row one");
});
