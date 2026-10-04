import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_142 — handles a system event and an application event", async ({page, host}) => {
  await openExample(page, host, 142);
  const tree = page.getByRole("tree");
  await tree.getByText("LH 0400").click();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Node LH0400 selected");
  await tree.getByText("UA 0941").dblclick();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Node UA0941 opened");
});
