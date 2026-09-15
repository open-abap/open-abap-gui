import {test, expect, openExample} from "../fixtures.mjs";

async function pressToolbar(page, label) {
  await page.locator(".wb-toolbar").getByRole("button", {name: label}).click();
  await page.waitForLoadState("load");
}

test("ZCL_GG_EX_143 — renders ALV hierarchy", async ({page, host}) => {
  await openExample(page, host, 143);
  const control = page.locator('[data-control-kind="ALV_TREE"]');
  const tree = control.getByRole("tree", {name: "ALV tree"});
  const columns = control.locator(".gg-alv-tree-columns table");
  await expect(control.locator(".gg-alv-tree")).toBeVisible();
  await expect(tree.getByRole("treeitem", {name: "LH400 — Lufthansa"})).toBeVisible();
  await expect(columns).toHaveAttribute("data-field-count", "3");
  await expect(columns.locator('[data-fieldname="SEATS"]').last()).toHaveAttribute("data-total", "true");
  const semantic = page.locator('.gg-structured-table[aria-label="ALV tree semantic rows"]');
  await expect(semantic).toContainText("Total seats: 550");
  await expect(page.locator(".gg-alv-tree-caption")).toContainText("Hierarchy columns");

  await pressToolbar(page, "Load lazy children");
  await expect(tree.getByRole("treeitem", {name: "Lazy child: UA901 United"})).toBeVisible();
  await pressToolbar(page, "Add leaf");
  await expect(tree.getByRole("treeitem", {name: "Added leaf: AF010 Air France"})).toBeVisible();
  await pressToolbar(page, "Collapse tree");
  await expect(tree.getByRole("treeitem", {name: "LH400 — Lufthansa"})).toBeHidden();
  await pressToolbar(page, "Expand tree");
  await expect(tree.getByRole("treeitem", {name: "LH400 — Lufthansa"})).toBeVisible();
  await pressToolbar(page, "Calculate totals");
  await expect(semantic).toContainText("Total seats: 550");
});

