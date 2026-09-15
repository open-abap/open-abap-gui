import {test, expect, openExample} from "../fixtures.mjs";

async function pressToolbar(page, label) {
  await page.locator(".wb-toolbar").getByRole("button", {name: label}).click();
  await page.waitForLoadState("load");
}

test("ZCL_GG_EX_141 — renders list and column tree headers", async ({page, host}) => {
  await openExample(page, host, 141);
  const table = page.getByRole("table", {name: "Column tree"});
  await expect(table).toContainText("On time");
  const items = page.getByRole("tree", {name: "Column tree item classes"});
  await expect(items.locator('[data-item-class="checkbox"]')).toHaveAttribute("aria-checked", "true");
  await expect(items.locator('[data-item-class="link"]')).toHaveAttribute("role", "link");
  await expect(items.locator('[data-item-class="button"]')).toHaveAttribute("role", "button");
  await expect(page.locator('[data-control-kind="LIST_TREE"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="COLUMN_TREE"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="LIST_TREE"]')).toBeHidden();
  await expect(page.locator('[data-control-kind="COLUMN_TREE"]')).toBeHidden();
  await pressToolbar(page, "Toggle status column");
  await expect(table).not.toContainText("On time");
});

