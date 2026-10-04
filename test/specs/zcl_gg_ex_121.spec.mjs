import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_121 — opens a dialog box container", async ({page, host}) => {
  await openExample(page, host, 121);
  await expect(page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Modal dialog body");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Dialog box open");
});
