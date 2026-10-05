import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_062 — Check switches the order to another status", async ({page, host}) => {
  await openExample(page, host, 62);
  const toolbar = page.locator(".wb-toolbar");
  const save = page.locator('.wb-commandbar button[title="Save"]');
  await expect(toolbar.getByRole("button")).toHaveText(["Check"]);
  await expect(save).toBeDisabled();

  await submit(page, "Check");
  await expect(page.locator(".gg-list-line")).toHaveText(["Order 4711, checked"]);
  await expect(toolbar.getByRole("button")).toHaveText(["Save"]);
  // The new status puts Save on Ctrl+S, the system toolbar's Save.
  await expect(save).toBeEnabled();
  await save.click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line")).toHaveText(["Order 4711, saved"]);
});
