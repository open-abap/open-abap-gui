import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_126 — shows the calendar around the focus date", async ({page, host}) => {
  await openExample(page, host, 126);
  await expect(page.locator('[data-control-kind="CALENDAR"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="CALENDAR"]')).toContainText("2026/8");
});
