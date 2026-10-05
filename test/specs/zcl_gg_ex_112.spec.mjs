import {test, expect, openExample, submit} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_112 — SET SCREEN lets PAI go on before the next screen", async ({page, host}) => {
  await openExample(page, host, 112);
  await submit(page, "SET SCREEN 200");
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(out(page, "GV_AFTER")).toHaveText("went on after SET SCREEN");
});

test("ZCL_GG_EX_112 — LEAVE TO SCREEN ends PAI at once", async ({page, host}) => {
  await openExample(page, host, 112);
  await submit(page, "LEAVE TO SCREEN 200");
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(out(page, "GV_AFTER")).toHaveText("ended at LEAVE TO SCREEN");
  await submit(page, "Back");
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
});
