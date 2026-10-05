import {test, expect, openExample, submit} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_110 — CALL SCREEN STARTING AT opens a modal dialog box", async ({page, host}) => {
  await openExample(page, host, 110);
  await submit(page, "Change name");
  const dialog = page.locator('[data-screen="0200"]');
  await expect(dialog).toHaveAttribute("data-modal", "true");
  await expect(page.getByRole("heading", {name: "Change name"})).toBeVisible();
  await page.locator('[name="GV_NEW_NAME"]').fill("Grace Hopper");
  await page.getByRole("button", {name: "Continue"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await expect(out(page, "GV_NAME")).toHaveText("Grace Hopper");
});

test("ZCL_GG_EX_110 — Cancel leaves the dialog without changes", async ({page, host}) => {
  await openExample(page, host, 110);
  await submit(page, "Change name");
  await page.locator('[name="GV_NEW_NAME"]').fill("Grace Hopper");
  await page.locator('[data-screen="0200"]').page().getByRole("button", {name: "Cancel"}).last().click();
  await page.waitForLoadState("load");
  await expect(out(page, "GV_NAME")).toHaveText("Ada Lovelace");
});
