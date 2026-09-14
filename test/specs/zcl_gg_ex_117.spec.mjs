import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_117 — preserves custom container and child identity", async ({page, host}) => {
  await openExample(page, host, 117);
  await expect(page.locator('[data-control-kind="CUSTOM_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Child control in custom container (generation 1)");
  await expect(page.locator(".gg-structured-table")).toContainText("ROOT117");
  await page.locator(".gg-structured-table").getByRole("button", {name: "Resize child"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-structured-table")).toContainText("520 x 120");
});

