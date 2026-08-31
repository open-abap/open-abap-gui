import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_010 — renders END-OF-PAGE footers`, async ({page, host}) => {
  await openExample(page, host, 10);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-page")).toHaveCount(4);
  await expect(page.locator('.gg-list-page[data-page="1"]')).toContainText("1");
  await expect(page.locator('.gg-list-page[data-page="1"]')).toContainText("8");
  await expect(page.locator('.gg-list-page[data-page="1"]')).toContainText("footer");
  await expect(page.locator('.gg-list-page[data-page="2"]')).toContainText("9");
  await expect(page.locator('.gg-list-page[data-page="2"]')).toContainText("16");
  await expect(page.locator('.gg-list-page[data-page="2"]')).toContainText("footer");
  await expect(page.locator('.gg-list-page[data-page="3"]')).toContainText("17");
  await expect(page.locator('.gg-list-page[data-page="3"]')).toContainText("24");
  await expect(page.locator('.gg-list-page[data-page="3"]')).toContainText("footer");
  await expect(page.locator('.gg-list-page[data-page="4"]')).toContainText("25");
  await expect(page.locator('.gg-list-page[data-page="4"]')).toContainText("30");
});
