import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_147 — dispatches SALV row events", async ({page, host}) => {
  await openExample(page, host, 147);
  await expect(page.getByText("ROW-2")).toBeVisible();
  await page.getByRole("button", {name: "Open LH400"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line").last()).toContainText("SALV link event");
});

