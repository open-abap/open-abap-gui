import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_84 — opaque row tokens restore independent hidden values", async ({page, host}) => {
  await openExample(page, host, 84);
  await submit(page, "Select line 2");
  await expect(page.locator(".gg-list-line").last()).toHaveText("selected bravo");
  await expect(page.locator("[data-action-token]")).toHaveCount(2);
  await expect(page.locator("[data-action-token]").nth(0)).not.toHaveAttribute("data-action-token", await page.locator("[data-action-token]").nth(1).getAttribute("data-action-token"));
});

