import {test, expect, openExample, dispatch, expectPageKind, clickHelp} from "../fixtures.mjs";

test("ZCL_GG_EX_102 — provides value help for an input", async ({page, host}) => {
  await openExample(page, host, 102);
  await clickHelp(page, "P_VALUE", "Value help for P_VALUE");
  await page.waitForLoadState("load");
  const modal = page.getByRole("dialog", {name: "Value help"});
  await expect(modal).toBeVisible();
  await expect(modal).toHaveAttribute("aria-modal", "true");
  await expect(page.getByRole("region", {name: "Value help"})).toContainText("AA");
  await expect(modal.getByRole("button", {name: "Close value help"})).toBeFocused();
  await modal.getByRole("button", {name: "Close value help"}).click();
  await expect(modal).toBeHidden();
  await expect(page.locator('[name="P_VALUE"]')).toBeFocused();
});

test("ZCL_GG_EX_102 — F4 opens the value help of the focused field", async ({page, host}) => {
  await openExample(page, host, 102);
  const help = page.getByRole("button", {name: "Value help for P_VALUE"});
  await expect(help).toBeHidden();
  await page.locator('[name="P_VALUE"]').focus();
  await expect(help).toBeVisible();
  await page.keyboard.press("F4");
  await page.waitForLoadState("load");
  await expect(page.getByRole("region", {name: "Value help"})).toContainText("AA");
});

test("ZCL_GG_EX_102 — double-clicking a value closes help and fills the field", async ({page, host}) => {
  await openExample(page, host, 102);
  await clickHelp(page, "P_VALUE", "Value help for P_VALUE");
  await page.waitForLoadState("load");
  await page.locator(".gg-value-help li").first().dblclick();
  await expect(page.locator('[name="P_VALUE"]')).toHaveValue("AA");
  await expect(page.getByRole("dialog", {name: "Value help"})).toBeHidden();
  await expect(page.locator('[name="P_VALUE"]')).toBeFocused();
});
