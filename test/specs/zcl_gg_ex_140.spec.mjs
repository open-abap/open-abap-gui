import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_140 — loads children when a node is expanded", async ({page, host}) => {
  await openExample(page, host, 140);
  const tree = page.getByRole("tree");
  await expect(tree.getByRole("treeitem")).toHaveCount(3);
  await submit(page, "Expand Lufthansa");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("2 flight(s) of LH loaded");
  await expect(tree.getByRole("treeitem")).toHaveCount(5);
  await tree.getByText("LH 0400 Frankfurt - New York").dblclick();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Double click on node LH0400");
  await tree.getByText("United Airlines").click();
  await expect(tree.locator('[data-node-key="UA"]')).toHaveAttribute("aria-selected", "true");
  await submit(page, "Selected node");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Selected node UA");
});
