import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_04 — formats numeric output`, async ({page, host}) => {
  await openExample(page, host, 4);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(1);
  await expect(page.locator(".gg-list")).toContainText("1234.50");
});
