import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_138 — exposes an opaque ALV selection", async ({page, host}) => {
  await openExample(page, host, 138);
  await expect(page.locator('[data-control-kind="ALV_GRID"] tr[data-row-index="2"]')).toHaveAttribute("selected", "");
  await expect(page.getByText("FLIGHT-2")).toBeVisible();
  await page.getByRole("button", {name: "Confirm selection"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toContainText("opaque row");
});

