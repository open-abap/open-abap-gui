import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_141 — shows a list tree and a column tree", async ({page, host}) => {
  await openExample(page, host, 141);
  await expect(page.locator('[data-control-kind="LIST_TREE"]')).toContainText("LH 0400");
  await expect(page.locator('[data-control-kind="LIST_TREE"] .gg-tree-item').first()).toHaveText("On time");
  const columns = page.locator('[data-control-kind="COLUMN_TREE"]');
  await expect(columns.locator("thead th")).toHaveText(["Flight", "Status"]);
  await expect(columns.locator('tr[data-node-key="UA0941"]')).toContainText("Delayed");
  await columns.getByRole("button", {name: "Collapse Flights"}).click();
  await expect(columns.locator('tr[data-node-key="UA0941"]')).toBeHidden();
});
