import {test, expect, openExample, submit, statusMessage} from "../fixtures.mjs";

const dynpro = (page) => page.locator('[data-screen="0100"]');
const remove = (page) => page.locator('.wb-toolbar [data-ucomm="UNDO"]');

test("ZCL_GG_EX_064 — title, excluded function and cursor follow the notes", async ({page, host}) => {
  await openExample(page, host, 64);
  await expect(page.getByRole("heading", {name: "Notes: 0"})).toBeVisible();
  // The excluded function is not shown in the application toolbar.
  await expect(remove(page)).toHaveCount(0);
  await expect(dynpro(page)).toHaveAttribute("data-cursor-field", "GV_TITLE");

  await submit(page, "Add note");
  await expect(page.getByRole("heading", {name: "Notes: 1"})).toBeVisible();
  await expect(statusMessage(page)).toContainText("Note 1 added, cursor was in GV_TITLE");
  await expect(remove(page)).toBeVisible();
  await expect(dynpro(page)).toHaveAttribute("data-cursor-field", "GV_NOTE");

  await submit(page, "Remove note");
  await expect(page.getByRole("heading", {name: "Notes: 0"})).toBeVisible();
  await expect(statusMessage(page)).toContainText("Note removed, cursor was in GV_NOTE");
  await expect(remove(page)).toHaveCount(0);
});
