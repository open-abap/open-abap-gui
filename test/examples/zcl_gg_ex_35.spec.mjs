import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_35 — executes value-request handling`, async ({page, host}) => {
  await openExample(page, host, 35);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toHaveCount(1);
});
