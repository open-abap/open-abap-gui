import {test, expect, openExample} from "../fixtures.mjs";

const node = (page, key) => page.locator(`[data-control-kind="SIMPLE_TREE"] li[data-node-key="${key}"]`);
const bookings = (page) => page.getByRole("table", {name: "Bookings"});

test("ZCL_GG_EX_153 — flights with a drag handle can be dragged, folders cannot", async ({page, host}) => {
  await openExample(page, host, 153);
  await expect(node(page, "LH0400")).toHaveAttribute("draggable", "true");
  await expect(node(page, "LH")).not.toHaveAttribute("draggable", "true");
  await expect(bookings(page).locator("tbody tr")).toHaveCount(0);
});

test("ZCL_GG_EX_153 — dropping a flight on the grid raises on_drag, then ondrop", async ({page, host}) => {
  await openExample(page, host, 153);
  const target = page.locator('[data-control-kind="ALV_GRID"] [data-gg-drop]');

  await node(page, "UA0941").locator(".gg-tree-label").dragTo(target);
  await page.waitForLoadState("load");
  await expect(bookings(page).locator("tbody tr")).toHaveCount(1);
  await expect(bookings(page).locator("tbody tr").first()).toContainText("San Francisco");

  await node(page, "LH0400").locator(".gg-tree-label").dragTo(target);
  await page.waitForLoadState("load");
  await expect(bookings(page).locator("tbody tr")).toHaveCount(2);
  await expect(bookings(page).locator("tbody tr").nth(1)).toContainText("0400");
});
