import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_117 — preserves custom container and child identity", async ({page, host}) => {
  await openExample(page, host, 117);
  await expect(page.locator('[data-control-kind="CUSTOM_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Child control in custom container");
});

