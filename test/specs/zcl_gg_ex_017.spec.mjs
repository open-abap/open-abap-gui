import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_017 — applies a checkbox default`, async ({page, host}) => {
  await openExample(page, host, 17);
  await expectPageKind(page, "SELECTION");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("X");
});
