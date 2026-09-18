import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_121 — renders titled modal container content", async ({page, host}) => {
  await openExample(page, host, 121);
  const dialog = page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]');
  await expect(dialog).toHaveAttribute("data-payload", "Dialog content");
  await expect(dialog).toHaveAttribute("aria-label", "Dialog content");
  await expect(dialog).not.toContainText("Dialog content");
  await expect(page.locator("textarea")).toHaveValue("Modal dialog body");
});

