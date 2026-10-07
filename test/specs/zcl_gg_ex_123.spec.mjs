import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_123 — shows read-only text", async ({page, host}) => {
  await openExample(page, host, 123);
  await expect(page.locator("textarea")).toHaveValue(/Read-only text/);
  // Read-only text cannot be edited but can still be focused, selected and copied.
  await expect(page.locator("textarea")).toBeEnabled();
  await expect(page.locator("textarea")).not.toBeEditable();
});
