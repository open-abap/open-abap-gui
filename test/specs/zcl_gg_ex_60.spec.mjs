import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_60 — preserves separator order and keyboard access", async ({page, host}) => {
  await openExample(page, host, 60);
  const toolbar = page.locator(".wb-toolbar");
  const buttons = toolbar.getByRole("button");
  await expect(buttons).toHaveCount(3);
  await expect(buttons.nth(0)).toHaveAccessibleName("First action");
  await expect(buttons.nth(1)).toHaveAccessibleName("Second action");
  await expect(buttons.nth(2)).toHaveAccessibleName("Print");
  await expect(toolbar.locator(".wb-toolbar-separator")).toHaveCount(2);
  await expect(buttons.nth(0)).toHaveAttribute("title", "First action");
  await expect(buttons.nth(1)).toHaveAttribute("title", "Second action");
  await buttons.nth(0).focus();
  await expect(buttons.nth(0)).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(buttons.nth(1)).toBeFocused();
  await expect(toolbar.locator(".wb-toolbar-separator button")).toHaveCount(0);
});

