import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_123 — disables readonly editor input", async ({page, host}) => {
  await openExample(page, host, 123);
  await expect(page.locator("textarea")).toBeDisabled();
  await expect(page.locator("textarea")).toContainText("Readonly Unicode text");
});

