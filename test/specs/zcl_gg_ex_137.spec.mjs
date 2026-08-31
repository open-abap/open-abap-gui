import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_137 — shows server-owned ALV criteria", async ({page, host}) => {
  await openExample(page, host, 137);
  await expect(page.locator('[data-criteria="server-owned"]')).toContainText("Lufthansa");
  await page.locator(".gg-external").getByRole("button", {name: "Apply criteria"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line").last()).toContainText("criteria applied server-side");
});

