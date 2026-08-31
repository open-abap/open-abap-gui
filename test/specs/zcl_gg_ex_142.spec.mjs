import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_142 — dispatches an opaque tree event", async ({page, host}) => {
  await openExample(page, host, 142);
  await expect(page.getByText("NODE-LH400")).toBeVisible();
  await page.locator(".gg-external").getByRole("button", {name: "Select node"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line").last()).toContainText("node NODE-LH400");
});

