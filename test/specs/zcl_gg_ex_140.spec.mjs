import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_140 — renders a simple tree fallback", async ({page, host}) => {
  await openExample(page, host, 140);
  await expect(page.getByRole("tree", {name: "Simple tree"})).toBeVisible();
  await expect(page.getByRole("treeitem", {name: "LH400 — Lufthansa"})).toBeVisible();
  await expect(page.getByText("Hidden audit node")).toBeHidden();
});

