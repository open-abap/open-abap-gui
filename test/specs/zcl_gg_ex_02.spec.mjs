import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_02 — preserves positioned and no-gap fields`, async ({page, host}) => {
  await openExample(page, host, 2);
  await expectPageKind(page, "LIST");
  const line = page.locator(".gg-list-line").first();
  await expect(line).toHaveCount(1);
  await expect(line.locator('[data-column="10"]')).toHaveText("abcde");
  await expect(line.locator('[data-column="16"]')).toHaveText("x");
  await expect(line.locator('[data-column="17"]')).toHaveText("y");
});
