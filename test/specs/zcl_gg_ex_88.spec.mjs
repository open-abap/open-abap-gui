import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_88 — renders semantic icons, symbols, checkbox, and quickinfo", async ({page, host}) => {
  await openExample(page, host, 88);
  await expect(page.locator(".gg-list-fragment")).toHaveCount(3);
  await expect(page.locator(".gg-list-fragment use")).toHaveCount(2);
  await expect(page.getByText("[selected]")).toBeVisible();
  await expect(page.locator('[title="Icon & <safe>"]')).toHaveCount(3);
});

