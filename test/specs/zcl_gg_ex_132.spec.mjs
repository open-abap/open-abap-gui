import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_132 — refreshes the control from PBO", async ({page, host}) => {
  await openExample(page, host, 132);
  await expect(page.locator("textarea")).toHaveValue("Control refreshed 0 times");
  await submit(page, "Refresh");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Refresh 1");
  await expect(page.locator("textarea")).toHaveValue("Control refreshed 1 times");
  await submit(page, "Enable/disable");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Editor disabled");
});
