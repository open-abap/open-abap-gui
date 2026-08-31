import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_120 — exposes a semantic docking region", async ({page, host}) => {
  await openExample(page, host, 120);
  await expect(page.locator('[data-control-kind="DOCKING_CONTAINER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Docked content");
});

