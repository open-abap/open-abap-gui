import {test, expect, openExample} from "../fixtures.mjs";

async function pressToolbar(page, label) {
  await page.locator(".wb-toolbar").getByRole("button", {name: label}).click();
  await page.waitForLoadState("load");
}

test("ZCL_GG_EX_147 — dispatches SALV row events", async ({page, host}) => {
  await openExample(page, host, 147);
  const tree = page.locator(".gg-salv-tree");
  await expect(tree).toBeVisible();
  await expect(tree).toContainText("SALV flight tree");
  await expect(tree.locator('tr[data-node-key="NODE-2"]')).toHaveAttribute("aria-selected", "true");
  await expect(tree.locator('a[data-salv-event="link-click"]')).toBeVisible();
  await expect(tree.getByRole("button", {name: "Inspect"})).toBeVisible();
  await pressToolbar(page, "Open row");
  await expect(page.getByText("SALV link event delivered for NODE-2 / FLIGHT")).toBeVisible();
  await pressToolbar(page, "Double-click row");
  await expect(page.getByText("SALV double-click event delivered for NODE-2 / FLIGHT")).toBeVisible();
  await pressToolbar(page, "Add leaf");
  await expect(tree.getByText("Added leaf: AF010 Air France")).toBeVisible();
  await pressToolbar(page, "Collapse tree");
  await expect(tree.locator('tr[data-node-key="NODE-2"]')).toBeHidden();
  await pressToolbar(page, "Expand tree");
  await expect(tree.locator('tr[data-node-key="NODE-2"]')).toBeVisible();
});

