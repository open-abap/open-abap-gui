import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_119 — renders the easy splitter fallback", async ({page, host}) => {
  await openExample(page, host, 119);
  await expect(page.locator('[data-control-kind="EASY_SPLITTER"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue("Easy splitter content");
});

