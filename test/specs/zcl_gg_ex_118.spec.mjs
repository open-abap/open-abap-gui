import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_118 — renders nested splitter regions", async ({page, host}) => {
  await openExample(page, host, 118);
  await expect(page.locator('[data-control-kind="SPLITTER_CONTAINER"]')).toHaveCount(2);
  await expect(page.locator("textarea")).toHaveCount(2);
  await expect(page.locator("textarea").first()).toHaveValue("Outer editor pane");
  await expect(page.locator("iframe")).toHaveCount(1);
  await expect(page.locator(".gg-structured-table")).toContainText("Minimum size");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Move row sash"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-structured-table")).toContainText("70 px");
});

