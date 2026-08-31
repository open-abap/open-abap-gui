import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_96 — preserves stacked message order and roles", async ({page, host}) => {
  await openExample(page, host, 96);
  await expect(page.locator(".gg-message")).toHaveCount(2);
  await expect(page.locator(".gg-message").nth(0)).toHaveText("Saved successfully");
  await expect(page.locator(".gg-message").nth(1)).toHaveText("Review the selection");
  await expect(page.locator(".gg-message").nth(0)).toHaveAttribute("role", "alert");
});

