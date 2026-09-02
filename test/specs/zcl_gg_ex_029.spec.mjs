import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_029 — executes selection-screen value mutation`, async ({page, host}) => {
  await openExample(page, host, 29);
  await expectPageKind(page, "SELECTION");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
});
