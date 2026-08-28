import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_31 — executes field-level selection validation`, async ({page, host}) => {
  await openExample(page, host, 31);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toHaveCount(1);
});
