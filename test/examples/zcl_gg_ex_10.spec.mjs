import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_10 — renders END-OF-PAGE footers`, async ({page, host}) => {
  await openExample(page, host, 10);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-page")).toHaveCount(4);
  await expect(page.locator(".gg-list")).toContainText("footer");
});
