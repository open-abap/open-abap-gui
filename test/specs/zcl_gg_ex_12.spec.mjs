import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_12 — applies INITIALIZATION values`, async ({page, host}) => {
  await openExample(page, host, 12);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(1);
  await expect(page.locator(".gg-list")).toContainText("20260101");
});
