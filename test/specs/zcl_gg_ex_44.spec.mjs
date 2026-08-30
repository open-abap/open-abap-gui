import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_44 — renders PF-STATUS and excluded commands`, async ({page, host}) => {
  await openExample(page, host, 44);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-status")).toContainText("LIST");
  await expect(page.getByRole("button", {name: "DEL"})).toBeDisabled();
  await expect(page.locator(".gg-list")).toContainText("body");
  const iconBar = page.locator(".wb-toolbar");
  await expect(iconBar.getByRole("button")).toHaveCount(2);
  await expect(iconBar.getByRole("button", {name: "Refresh"})).toHaveAttribute("data-ucomm", "REFR");
  await expect(iconBar.getByRole("button", {name: "Refresh"}).locator("use")).toHaveAttribute("href", "#wb-icon-refresh");
  await expect(iconBar.getByRole("button", {name: "Print"}).locator("use")).toHaveAttribute("href", "#wb-icon-printer");
  await dispatch(page, {action: "COMMAND", ucomm: "REFR"});
  await expect(page.locator(".gg-list-line")).toHaveText(["body", "refreshed"]);
});

test(`ZCL_GG_EX_44 — the status activates the standard print command`, async ({page, host}) => {
  await openExample(page, host, 44);

  const commandBar = page.locator(".wb-commandbar");
  await expect(commandBar.locator('[title="Print"]')).toBeEnabled();
  await expect(commandBar.locator('[title="Save"]')).toBeDisabled();
  await expect(commandBar.locator('[title="Find"]')).toBeDisabled();

  await commandBar.locator('[title="Print"]').click();
  await page.waitForLoadState("networkidle");
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["body", "printed"]);
});
