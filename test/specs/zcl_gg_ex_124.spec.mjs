import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_124 — loads and lays out a picture", async ({page, host}) => {
  await openExample(page, host, 124);
  await expect(page.locator('[data-control-kind="PICTURE"]')).toHaveCount(1);
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Picture loaded");
  await submit(page, "Fit and center");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Fit and centered");
});
