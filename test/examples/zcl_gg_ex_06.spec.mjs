import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_06 — renders checkbox, icon, and symbol fields`, async ({page, host}) => {
  await openExample(page, host, 6);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("[selected]");
  await expect(page.locator(".gg-list")).toContainText("ICON_GREEN_LIGHT");
  await expect(page.locator(".gg-list")).toContainText("SYM_PHONE");
});
