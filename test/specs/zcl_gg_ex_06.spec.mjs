import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_06 — renders checkbox, icon, and symbol fields`, async ({page, host}) => {
  await openExample(page, host, 6);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-fragment")).toHaveCount(3);
  await expect(page.locator(".gg-list-fragment").nth(0)).toHaveText("[selected]");
  await expect(page.locator(".gg-list-fragment").nth(1)).toHaveText("[@ICON_GREEN_LIGHT@]");
  await expect(page.locator(".gg-list-fragment").nth(2)).toHaveText("[@SYM_PHONE@]");
  await expect(page.locator(".gg-list-fragment").nth(1).locator("use")).toHaveAttribute(
    "href",
    "#wb-icon-circle-check",
  );
  await expect(page.locator(".gg-list-fragment").nth(2).locator("use")).toHaveAttribute(
    "href",
    "#wb-icon-help-circle",
  );
});
