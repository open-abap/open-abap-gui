import {test, expect, openExample, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_053 — SUBMIT without AND RETURN runs the submitted report`, async ({page, host}) => {
  await openExample(page, host, 53);
  // The submitting program ends and ZGG_EX_001 takes its place.
  await expectPageKind(page, "LIST");
  await expect(page.locator(".wb-app-title")).toHaveText("ZCL_GG_EX_001");
  await expect(page.locator(".gg-list")).toContainText("hello world");
});
