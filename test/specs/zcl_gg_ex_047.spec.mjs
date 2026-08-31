import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_047 — exposes a cursor-aware list report`, async ({page, host}) => {
  await openExample(page, host, 47);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await expect(page.getByRole("button", {name: /Select line/})).toHaveCount(0);
});
