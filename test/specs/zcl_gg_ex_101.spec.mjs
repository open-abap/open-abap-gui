import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_101 — SET CURSOR puts the cursor on the empty field", async ({page, host}) => {
  await openExample(page, host, 101);
  await expect(page.locator('[data-screen="0100"]')).toHaveAttribute("data-cursor-field", "GV_CITY");
  await expect(page.locator('[name="GV_CITY"]')).toBeFocused();
});

test("ZCL_GG_EX_101 — an error in a FIELD module keeps only that field open", async ({page, host}) => {
  await openExample(page, host, 101);
  await page.locator(".wb-toolbar").getByRole("button", {name: "Validate"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("alert")).toContainText("Enter a city");
  await expect(page.locator('[name="GV_CITY"]')).toHaveAttribute("aria-invalid", "true");
  await expect(page.locator('[name="GV_CITY"]')).toBeEditable();
  await expect(page.locator('[name="GV_NAME"]')).not.toBeEditable();

  await page.locator('[name="GV_CITY"]').fill("Paris");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Validate"}).click();
  await page.waitForLoadState("load");
  await expect(out(page, "GV_STATE")).toHaveText("Ada lives in Paris");
  await expect(page.locator('[name="GV_NAME"]')).toBeEditable();
});
