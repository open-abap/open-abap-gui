import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_120 — docks a container at the screen", async ({page, host}) => {
  await openExample(page, host, 120);
  await expect(page.locator('[data-control-kind="DOCKING_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Docked content");
  await submit(page, "Extend dock");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Dock extension 320 pixels");
});
