import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_045 — renders the SET TITLEBAR title`, async ({page, host}) => {
  await openExample(page, host, 45);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".wb-app-title")).toHaveText("MAIN");
  await expect(page.locator("main h1")).toHaveCount(0);
  await expect(page.locator(".gg-list-line")).toHaveText("body");
});
