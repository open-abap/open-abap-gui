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

test("ZCL_GG_EX_143 — supports tree keyboard and row interactions", async ({page, host}) => {
  await openExample(page, host, 143);
  await page.evaluate(() => {
    window.__ggDisableTreeTransport = true;
    window.__ggTreeEvents = [];
    ["gg-alv-tree-toggle", "gg-alv-tree-select", "gg-alv-tree-node-double-click"].forEach((name) => {
      document.addEventListener(name, (event) => window.__ggTreeEvents.push({name, ...event.detail}));
    });
  });

  const tree = page.locator('[data-control-kind="ALV_TREE"] [role="tree"]');
  const folder = tree.locator('tr[data-has-children="true"]').first();
  await folder.focus();
  await folder.press("ArrowLeft");
  await expect(folder).toHaveAttribute("aria-expanded", "false");
  await expect(folder.locator('[data-tree-action="toggle"]')).toHaveAttribute("aria-label", /Expand/);
  await folder.press("ArrowRight");
  await expect(folder).toHaveAttribute("aria-expanded", "true");

  await folder.click();
  await expect(folder).toHaveAttribute("aria-selected", "true");
  await folder.press("Enter");
  await expect.poll(async () => page.evaluate(() => window.__ggTreeEvents.map((event) => event.name)))
    .toEqual(expect.arrayContaining(["gg-alv-tree-toggle", "gg-alv-tree-select", "gg-alv-tree-node-double-click"]));
});

