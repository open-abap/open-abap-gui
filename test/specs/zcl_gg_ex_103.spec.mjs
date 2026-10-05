import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_103 — LOOP AT SCREEN shows and requires a field", async ({page, host}) => {
  await openExample(page, host, 103);
  const address = page.locator('[name="GV_ADDRESS"]');
  const delivery = page.getByLabel("Separate delivery address");
  await expect(address).toBeHidden();
  await delivery.check();
  await page.waitForLoadState("load");
  await expect(address).toBeVisible();
  await expect(address).toHaveAttribute("required", "");

  // The field is required now: as on SAP, PAI runs only with it filled.
  await delivery.uncheck();
  await page.waitForLoadState("load");
  await expect(page.getByRole("alert")).toContainText("Fill in all required entry fields");
  await expect(address).toBeVisible();

  // The box stays as the user left it; Enter runs PAI again.
  await expect(delivery).not.toBeChecked();
  await address.fill("Main Street 1");
  await address.press("Enter");
  await page.waitForLoadState("load");
  await expect(address).toBeHidden();
});
