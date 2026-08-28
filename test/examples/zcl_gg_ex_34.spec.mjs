import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_34 — executes radio-group validation`, async ({page, host}) => {
  await openExample(page, host, 34);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toHaveCount(1);
});
