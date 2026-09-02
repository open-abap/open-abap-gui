import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_025 — executes a function-key report`, async ({page, host}) => {
  await openExample(page, host, 25);
  await expectPageKind(page, "SELECTION");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
});
