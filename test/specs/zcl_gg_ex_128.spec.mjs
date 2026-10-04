import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_128 — shows program HTML without running its scripts", async ({page, host}) => {
  await openExample(page, host, 128);
  const viewer = page.frameLocator('iframe[title="HTML viewer"]');
  await expect(viewer.locator("h2")).toHaveText("Sandboxed viewer");
  await expect(page.locator('iframe[title="HTML viewer"]')).not.toHaveAttribute("sandbox", /allow-scripts/);
  await expect(page).not.toHaveTitle("script ran");
});
