import {test, expect, openExample, submit} from "../fixtures.mjs";

const calendar = (page) => page.locator('[data-control-kind="CALENDAR"]');
const field = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_159 — shows ten months around the focus date", async ({page, host}) => {
  await openExample(page, host, 159);
  const months = calendar(page).locator(".gg-calendar-month-heading");
  await expect(months.first()).toHaveText("2026/4");
  await expect(months).toContainText(["2026/8", "2027/1"]);
  await expect(calendar(page).locator('td[aria-selected="true"]')).toHaveCount(0);
});

test("ZCL_GG_EX_159 — clicking a day selects its week and raises date_selected", async ({page, host}) => {
  await openExample(page, host, 159);
  await calendar(page).getByRole("button", {name: "2026-09-09"}).click();
  await page.waitForLoadState("load");
  await expect(field(page, "GV_WEEK_BEGIN")).toHaveText("07.09.2026");
  await expect(field(page, "GV_WEEK_END")).toHaveText("13.09.2026");
  const selected = calendar(page).locator('td[aria-selected="true"]');
  await expect(selected).toHaveCount(7);
  await expect(selected.first()).toHaveAttribute("data-date", "20260907");

  await submit(page, "Clear selection");
  await expect(field(page, "GV_WEEK_BEGIN")).toHaveText("");
  await expect(calendar(page).locator('td[aria-selected="true"]')).toHaveCount(0);
});

test("ZCL_GG_EX_159 — go_to_date moves the visible months", async ({page, host}) => {
  await openExample(page, host, 159);
  await page.getByRole("button", {name: "2027", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(calendar(page).locator(".gg-calendar-month-heading").first()).toHaveText("2027/4");
  await page.getByRole("button", {name: "2026", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(calendar(page).locator(".gg-calendar-month-heading").first()).toHaveText("2026/4");
});
