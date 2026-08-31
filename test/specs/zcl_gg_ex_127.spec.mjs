import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_127 — renders escaped selector options", async ({page, host}) => {
  await openExample(page, host, 127);
  const selector = page.locator('select[aria-label="Selector"]');
  await expect(selector.locator("option")).toHaveCount(3);
  await expect(selector.locator("option").nth(1)).toHaveText("Lufthansa");
  await expect(selector.locator("option").nth(1)).toHaveAttribute("value", "LH");
});

