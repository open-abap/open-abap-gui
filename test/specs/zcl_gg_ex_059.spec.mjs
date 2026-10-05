import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_059 — the application toolbar shows the status's icons and separator", async ({page, host}) => {
  await openExample(page, host, 59);
  const toolbar = page.locator(".wb-toolbar");
  await expect(toolbar.getByRole("button")).toHaveText(["Refresh", "Add seat", "Remove seat"]);
  await expect(toolbar.getByRole("button", {name: "Refresh"}).locator("use")).toHaveAttribute("href", "#wb-icon-refresh");
  await expect(toolbar.getByRole("button", {name: "Add seat"}).locator("use")).toHaveAttribute("href", "#wb-icon-plus");
  await expect(toolbar.getByRole("button", {name: "Remove seat"}).locator("use")).toHaveAttribute("href", "#wb-icon-trash");
  // The separator stands between Refresh and the functions that change the booking.
  await expect(toolbar.locator(".wb-toolbar-separator")).toHaveCount(1);
  await expect(toolbar.locator(".wb-toolbar-separator + button")).toHaveAccessibleName("Add seat");

  await submit(page, "Add seat");
  await expect(page.locator(".gg-list-line")).toHaveText(["Ada Lovelace, flight LH 0400: 3 seats"]);
});
