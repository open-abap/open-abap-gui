import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_118 — renders nested splitter regions", async ({page, host}) => {
  await openExample(page, host, 118);
  await expect(page.locator('[data-control-kind="SPLITTER_CONTAINER"]')).toHaveCount(2);
  await expect(page.locator("textarea")).toHaveValue("Nested horizontal pane");
});

