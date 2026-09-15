import {test, expect, openExample} from "../fixtures.mjs";

async function pressToolbar(page, label) {
  await page.locator(".wb-toolbar").getByRole("button", {name: label}).click();
  await page.waitForLoadState("load");
}

test("ZCL_GG_EX_140 — renders a simple tree fallback", async ({page, host}) => {
  await openExample(page, host, 140);
  const tree = page.getByRole("tree", {name: "Simple tree"});
  await expect(tree).toBeVisible();
  await expect(tree.getByRole("treeitem", {name: "LH400 — Lufthansa"})).toBeVisible();
  await expect(tree.locator('[data-item-class="checkbox"]')).toHaveAttribute("role", "checkbox");
  await expect(tree.locator('[data-item-class="editable"]')).toHaveAttribute("role", "textbox");
  await expect(page.getByText("Hidden audit node")).toBeHidden();
  await pressToolbar(page, "Collapse tree");
  await expect(tree.getByRole("treeitem", {name: "Seats: 180"})).toBeHidden();
  await pressToolbar(page, "Load children");
  await expect(tree.getByRole("treeitem", {name: "Lazy child: United"})).toBeVisible();
  await pressToolbar(page, "Context menu");
  await expect(page.getByText("Context menu: Open details, Rename, and Remove are server-declared actions.")).toBeVisible();
  await pressToolbar(page, "Compare models");
  await expect(page.locator(".gg-list-status")).toHaveText("TREE COMPARE");
  await expect(page.getByText(/Compare: simple model expands \d+ node\(s\) vs list model \d+/)).toBeVisible();
});

