import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_131 — keeps nested control registry order stable", async ({page, host}) => {
  await openExample(page, host, 131);
  await expect(page.locator('[data-control-kind="CUSTOM_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="SPLITTER_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Nested registry editor");
  await expect(page.locator('[data-control-kind="PICTURE"] img')).toHaveCount(1);
  await expect(page.locator('[role="toolbar"]')).toHaveCount(1);
});

