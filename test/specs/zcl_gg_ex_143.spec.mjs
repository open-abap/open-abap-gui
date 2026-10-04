import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_143 — shows flights below their airlines in an ALV tree", async ({page, host}) => {
  await openExample(page, host, 143);
  const tree = page.locator('[data-control-kind="ALV_TREE"]');
  await expect(tree.getByRole("treeitem", {name: "LH 0402"})).toBeVisible();
  await expect(tree.locator('tr[data-node-key="TREE-3"]')).toContainText("240");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("3 flights below their airlines");
});
