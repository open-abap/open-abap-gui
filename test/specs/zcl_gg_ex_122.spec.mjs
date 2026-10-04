import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_122 — edits text with a protected first line", async ({page, host}) => {
  await openExample(page, host, 122);
  await expect(page.locator("textarea")).toHaveValue(/First line\nSecond line\nThird line/);
  await submit(page, "Save text");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText(/^Saved \d+ characters$/);
});
