import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_07 — renders report line settings output`, async ({page, host}) => {
  await openExample(page, host, 7);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("body");
});
