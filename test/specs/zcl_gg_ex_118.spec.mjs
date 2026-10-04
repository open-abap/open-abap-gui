import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_118 — nests splitter containers", async ({page, host}) => {
  await openExample(page, host, 118);
  await expect(page.locator('[data-control-kind="TEXTEDIT"]')).toHaveCount(2);
  await expect(page.frameLocator('iframe[title="HTML viewer"]').locator("body")).toContainText("HTML viewer pane");
  await submit(page, "Move row sash");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Top row height 25 %");
});
