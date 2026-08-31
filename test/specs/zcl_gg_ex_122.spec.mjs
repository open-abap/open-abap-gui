import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_122 — keeps multiline editor text intact", async ({page, host}) => {
  await openExample(page, host, 122);
  await expect(page.locator("textarea")).toHaveValue("First line\nSecond line\nUnicode: 航空 🚀");
});

