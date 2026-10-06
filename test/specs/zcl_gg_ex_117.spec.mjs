import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_117 — hosts a text editor in a custom container", async ({page, host}) => {
  await openExample(page, host, 117);
  await expect(page.locator('[data-control-kind="CUSTOM_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Text editor in custom container CC_MAIN, generation 1");
  await submit(page, "Replace child");
  await expect(page.locator("textarea")).toHaveCount(1);
  await expect(page.locator("textarea:visible")).toHaveValue(/generation 2/);
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Child created, generation 2");
});
