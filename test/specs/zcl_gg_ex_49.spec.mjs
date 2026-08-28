import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_49 — renders a PF event report`, async ({page, host}) => {
  await openExample(page, host, 49);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("body");
});
