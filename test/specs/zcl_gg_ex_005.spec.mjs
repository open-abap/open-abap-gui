import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_005 — renders FORMAT attributes per fragment`, async ({page, host}) => {
  await openExample(page, host, 5);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-color-key.gg-intensified")).toHaveText("key column");
  await expect(page.locator(".gg-color-normal")).toHaveText("plain");
  await expect(page.locator(".gg-list-fragment")).toHaveCount(2);
});
