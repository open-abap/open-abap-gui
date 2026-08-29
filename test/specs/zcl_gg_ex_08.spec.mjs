import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_08 — renders a second page after NEW-PAGE`, async ({page, host}) => {
  await openExample(page, host, 8);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-page")).toHaveCount(2);
  await expect(page.locator('.gg-list-page[data-page="1"]')).toContainText("page one");
  await expect(page.locator('.gg-list-page[data-page="2"]')).toContainText("page two");
});
