import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_120 — preserves dock and main-area state", async ({page, host}) => {
  await openExample(page, host, 120);
  const dock = page.locator('[data-control-kind="DOCKING_CONTAINER"]');
  await expect(dock).toHaveCount(1);
  await expect(dock).toHaveAttribute("data-payload", /side=1/);
  await expect(dock).not.toContainText("side=1");
  await expect(page.locator(".gg-structured-table")).toContainText("Main diagnostic area");
  await expect(page.locator("textarea")).toHaveValue("Docked content");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Extend dock"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-structured-table")).toContainText("260 px");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Toggle dock"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-control-kind="DOCKING_CONTAINER"]')).toHaveAttribute("hidden", "");
  await expect(page.locator(".gg-structured-table")).toContainText("Visible");
});

