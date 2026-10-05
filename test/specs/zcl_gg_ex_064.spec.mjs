import {test, expect, openExample, submit} from "../fixtures.mjs";

const dynpro = (page) => page.locator('[data-screen="0100"]');
const remove = (page) => page.locator('.wb-toolbar [data-ucomm="UNDO"]');

test("ZCL_GG_EX_064 — title, excluded function and cursor follow the notes", async ({page, host}) => {
  await openExample(page, host, 64);
  await expect(page.getByRole("heading", {name: "Notes: 0"})).toBeVisible();
  await expect(remove(page)).toBeDisabled();
  await expect(dynpro(page)).toHaveAttribute("data-cursor-field", "GV_TITLE");

  await submit(page, "Add note");
  await expect(page.getByRole("heading", {name: "Notes: 1"})).toBeVisible();
  await expect(page.getByRole("alert")).toContainText("Note 1 added, cursor was in GV_TITLE");
  await expect(remove(page)).toBeEnabled();
  await expect(dynpro(page)).toHaveAttribute("data-cursor-field", "GV_NOTE");

  await submit(page, "Remove note");
  await expect(page.getByRole("heading", {name: "Notes: 0"})).toBeVisible();
  await expect(page.getByRole("alert")).toContainText("Note removed, cursor was in GV_NOTE");
  await expect(remove(page)).toBeDisabled();
});
