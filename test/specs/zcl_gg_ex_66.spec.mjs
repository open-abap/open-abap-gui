import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_66 — escapes hostile Unicode shell text", async ({page, host}) => {
  await openExample(page, host, 66);
  await expect(page.locator(".wb-app-title")).toContainText("RTL שלום 🚀 & <title>");
  await expect(page.locator(".wb-toolbar").getByRole("button", {name: 'Run "now" & <go> 🚀'})).toBeEnabled();
  await expect(page.locator(".gg-list-line")).toContainText('مرحبا é 🚀 <shell> & "quotes"');
  await page.locator(".wb-toolbar").getByRole("button", {name: 'Run "now" & <go> 🚀'}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line").last()).toContainText("accepted <command>");
});

