import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_22 — executes a framed selection block report`, async ({page, host}) => {
  await openExample(page, host, 22);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toHaveCount(1);
});
