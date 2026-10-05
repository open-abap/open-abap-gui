import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_103 — LOOP AT SCREEN shows and requires a field", async ({page, host}) => {
  await openExample(page, host, 103);
  await expect(page.locator('[name="GV_ADDRESS"]')).toBeHidden();
  await page.getByLabel("Separate delivery address").check();
  await page.waitForLoadState("load");
  await expect(page.locator('[name="GV_ADDRESS"]')).toBeVisible();
  await expect(page.locator('[name="GV_ADDRESS"]')).toHaveAttribute("required", "");
  await page.getByLabel("Separate delivery address").uncheck();
  await page.waitForLoadState("load");
  await expect(page.locator('[name="GV_ADDRESS"]')).toBeHidden();
});
