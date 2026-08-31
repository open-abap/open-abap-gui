import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_143 — renders ALV hierarchy", async ({page, host}) => {
  await openExample(page, host, 143);
  await expect(page.locator('[data-control-kind="ALV_TREE"]')).toContainText("LH400");
  await expect(page.locator(".gg-alv-tree-caption")).toContainText("Hierarchy columns");
});

