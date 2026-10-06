import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_138 — reads the rows the user selected", async ({page, host}) => {
  await openExample(page, host, 138);
  await expect(page.getByLabel("Select row 2")).toHaveAttribute("aria-pressed", "true");
  await submit(page, "Show selection");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Selected: UA 0941");
  await page.getByLabel("Select row 3").click();
  await submit(page, "Show selection");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Selected: UA 0941 AF 0010");
});
