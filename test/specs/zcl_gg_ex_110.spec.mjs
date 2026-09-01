import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_110 — opens a modal dynpro screen", async ({page, host}) => {
  await openExample(page, host, 110);
  await page.locator('[data-screen="0100"]').getByRole("button", {name: "Open dialog", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-screen="0200"]')).toHaveAttribute("data-modal", "true");
  await expect(page.getByRole("heading", {name: "ZCL_GG_EX_110"})).toBeVisible();
});

