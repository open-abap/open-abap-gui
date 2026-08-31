import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_126 — round-trips calendar focus and selection dates", async ({page, host}) => {
  await openExample(page, host, 126);
  await expect(page.locator('[aria-label="Calendar"] input[type="date"]')).toHaveValue("2026-08-30");
  await expect(page.locator('[aria-label="Calendar"]')).toContainText("20260830/20260901");
});

