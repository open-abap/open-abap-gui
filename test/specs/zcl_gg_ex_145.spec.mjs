import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_145 — renders SALV totals and filter action", async ({page, host}) => {
  await openExample(page, host, 145);
  await expect(page.locator('[data-aggregation="total"]')).toHaveText("Total seats: 550");
  await page.getByRole("button", {name: "Apply server filter"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toContainText("SALV filter applied");
});

