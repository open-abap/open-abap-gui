import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_104 — an error in a CHAIN keeps every field of the chain open", async ({page, host}) => {
  await openExample(page, host, 104);
  await page.locator('[name="GV_TO"]').fill("Frankfurt");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Check"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("alert")).toContainText("From and to must differ");
  await expect(page.locator('[name="GV_FROM"]')).toBeEditable();
  await expect(page.locator('[name="GV_TO"]')).toBeEditable();
  // The cursor goes to the first field of the chain.
  await expect(page.locator('[name="GV_FROM"]')).toHaveAttribute("aria-invalid", "true");
  await expect(page.locator('[data-screen="0100"]')).toHaveAttribute("data-cursor-field", "GV_FROM");

  await page.locator('[name="GV_TO"]').fill("Paris");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Check"}).click();
  await page.waitForLoadState("load");
  await expect(out(page, "GV_STATE")).toHaveText("Frankfurt to Paris");
});
