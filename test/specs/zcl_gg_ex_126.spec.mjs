import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_126 — round-trips calendar focus and selection dates", async ({page, host}) => {
  await openExample(page, host, 126);
  const calendar = page.locator('.gg-control[data-control-kind="CALENDAR"]');
  await expect(calendar.locator('.gg-calendar-week-grid')).toBeVisible();
  await expect(calendar.locator('.gg-calendar-month-heading').first()).toHaveText("2026/4");
  await expect(calendar.locator('.gg-calendar-month-heading').last()).toHaveText("2027/1");
  await expect(calendar.locator('.gg-calendar-week-grid')).toContainText("WN");
  await expect(calendar.locator('input[type="date"]')).toHaveCount(0);
  await expect(calendar).toHaveAttribute("data-date-range", "20260830/20260901");
  await expect(calendar).not.toContainText("20260830/20260901");
  await expect(calendar.locator('[data-date="20260830"]')).toHaveAttribute("aria-selected", "true");
  await expect(calendar.locator('[data-date="20260901"]')).toHaveAttribute("aria-selected", "true");
  await expect(calendar.locator('[data-date="20260902"]')).toHaveAttribute("aria-selected", "false");
});

