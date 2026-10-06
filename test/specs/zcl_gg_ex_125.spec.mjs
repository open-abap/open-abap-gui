import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_125 — sends toolbar functions to the program", async ({page, host}) => {
  await openExample(page, host, 125);
  await expect(page.getByRole("button", {name: "Disabled"})).toBeDisabled();
  await submit(page, "Run");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Toolbar function RUN");
  await expect(page.getByRole("menuitem", {name: "Menu action"})).toBeHidden();
  await page.locator(".gg-toolbar-dropdown summary").click();
  await page.getByRole("menuitem", {name: "Menu action"}).click();
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Toolbar function MENU_ACTION");
});
