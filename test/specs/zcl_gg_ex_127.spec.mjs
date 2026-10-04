import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_127 — selects a carrier from a dropdown listbox", async ({page, host}) => {
  await openExample(page, host, 127);
  await expect(page.locator('[name="GV_CARRIER"] option')).toHaveText(["Alpha Airlines", "Lufthansa", "United"]);
  await expect(page.locator('[name="GV_CARRIER"]')).toHaveValue("LH");
});
