import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_121 — renders titled modal container content", async ({page, host}) => {
  await openExample(page, host, 121);
  await expect(page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]')).toContainText("Dialog content");
  await expect(page.locator("textarea")).toHaveValue("Modal dialog body");
});

