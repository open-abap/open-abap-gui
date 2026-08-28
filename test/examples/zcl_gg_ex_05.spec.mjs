import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_05 — renders FORMAT attributes per fragment`, async ({page, host}) => {
  await openExample(page, host, 5);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-color-key.gg-intensified")).toContainText("key column");
  await expect(page.locator(".gg-color-normal")).toContainText("plain");
});
