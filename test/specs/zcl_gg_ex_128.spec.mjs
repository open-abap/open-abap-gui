import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_128 — shows program HTML without running its scripts", async ({page, host}) => {
  await openExample(page, host, 128);
  const viewer = page.frameLocator('iframe[title="HTML viewer"]');
  await expect(viewer.locator("h2")).toHaveText("Sandboxed viewer");
  await expect(page.locator('iframe[title="HTML viewer"]')).not.toHaveAttribute("sandbox", /allow-scripts/);
  await expect(page).not.toHaveTitle("script ran");
});

test("ZCL_GG_EX_128 — a SAPEVENT link of the document reaches the handler", async ({page, host}) => {
  await openExample(page, host, 128);
  await page.frameLocator('iframe[title="HTML viewer"]').getByRole("button", {name: "Confirm"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("SAPEVENT CONFIRM");
});
