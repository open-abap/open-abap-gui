import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_111 — nests modal screen transitions", async ({page, host}) => {
  await openExample(page, host, 111);
  await page.locator('[data-screen="0100"]').getByRole("button", {name: "Open first", exact: true}).click();
  await page.waitForLoadState("load");
  await page.locator('[data-screen="0200"]').getByRole("button", {name: "Open second", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-screen="0300"]')).toHaveAttribute("data-modal", "true");
  await expect(page.locator('[name="P_NESTED"]')).toHaveValue("nested value");
});

