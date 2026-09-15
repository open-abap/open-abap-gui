import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_148 — exposes an accessible bar chart fallback", async ({page, host}) => {
  await openExample(page, host, 148);
  await expect(page.locator('[data-control-kind="BARCHART"]')).toHaveCount(1);
  await expect(page.locator(".gg-list-status")).toContainText("GRAPHICS FALLBACK");
  await expect(page.locator(".gg-chart-fallback")).toHaveAttribute("data-native-capability", "unavailable");
  await expect(page.locator(".gg-chart-fallback")).toContainText("accessible table fallback");
  await expect(page.locator(".gg-chart-fallback table")).toContainText("Lufthansa");
  await expect(page.locator(".gg-chart-fallback table")).toContainText("42");
  await expect(page.locator('.gg-chart-fallback input[type="color"]')).toHaveValue("#2668a3");
  await page.locator('.gg-chart-fallback input[type="color"]').evaluate((input) => {
    input.value = "#ff0000";
  });
  await page.getByRole("button", {name: "Apply color"}).click();
  await expect(page.locator("body")).toContainText("Chart color set to #FF0000");
  await expect(page.locator('.gg-chart-fallback input[type="color"]')).toHaveValue("#ff0000");
});

