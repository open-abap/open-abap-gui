import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_123 — shows read-only text", async ({page, host}) => {
  await openExample(page, host, 123);
  await expect(page.locator("textarea")).toHaveValue(/Read-only text/);
  await expect(page.locator("textarea")).toBeDisabled();
});
