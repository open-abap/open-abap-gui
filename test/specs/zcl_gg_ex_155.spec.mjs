import {test, expect, openExample, submit} from "../fixtures.mjs";

const state = (page) => page.locator("#gg-dynpro-control-n-GV_STATE");
const dialog = (page) => page.getByRole("dialog", {name: "Flight notes"});

test("ZCL_GG_EX_155 — opens a modeless dialog box at its position", async ({page, host}) => {
  await openExample(page, host, 155);
  await expect(page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]')).toHaveCount(0);
  await submit(page, "Open dialog");
  await expect(dialog(page)).toBeVisible();
  await expect(dialog(page)).toHaveAttribute("aria-modal", "false");
  await expect(dialog(page).locator("textarea")).toHaveValue("LH 0400 leaves Frankfurt at 10:10.");
  await expect(dialog(page)).toHaveCSS("left", "360px");
  await expect(dialog(page)).toHaveCSS("top", "100px");
  await expect(state(page)).toHaveText("Dialog box open");
});

test("ZCL_GG_EX_155 — the main screen stays usable while the dialog is open", async ({page, host}) => {
  await openExample(page, host, 155);
  await submit(page, "Open dialog");
  await submit(page, "Use main screen");
  await expect(state(page)).toHaveText("Main screen used 1 times");
  await expect(dialog(page)).toBeVisible();
});

test("ZCL_GG_EX_155 — moves and resizes the dialog box", async ({page, host}) => {
  await openExample(page, host, 155);
  await submit(page, "Open dialog");
  await submit(page, "Move");
  await expect(state(page)).toHaveText("Dialog box at 400, 120");
  await expect(dialog(page)).toHaveCSS("left", "400px");
  await expect(dialog(page)).toHaveCSS("top", "120px");
  await submit(page, "Resize");
  await expect(state(page)).toHaveText("Dialog box 360 x 180");
  await expect(dialog(page)).toHaveCSS("width", "360px");
  await expect(dialog(page)).toHaveCSS("height", "180px");
});

test("ZCL_GG_EX_155 — the close button raises CLOSE and the handler frees the dialog", async ({page, host}) => {
  await openExample(page, host, 155);
  await submit(page, "Open dialog");
  await dialog(page).getByRole("button", {name: "Close"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]')).toHaveCount(0);

  // The handler cleared the reference, so the dialog box can be opened again.
  await submit(page, "Open dialog");
  await expect(dialog(page)).toBeVisible();
});
