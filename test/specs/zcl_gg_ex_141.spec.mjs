import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_141 — renders list and column tree headers", async ({page, host}) => {
  await openExample(page, host, 141);
  await expect(page.getByRole("table", {name: "Column tree"})).toContainText("On time");
  await expect(page.locator('[data-control-kind="LIST_TREE"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="COLUMN_TREE"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="LIST_TREE"]')).toBeHidden();
  await expect(page.locator('[data-control-kind="COLUMN_TREE"]')).toBeHidden();
});

