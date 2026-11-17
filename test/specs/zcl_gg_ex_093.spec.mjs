import {test, expect, openExample, statusMessage} from "../fixtures.mjs";

const found = (page) => page.locator(".gg-list-line[data-found]");

test("list shortcuts open Find and search options control matching", async ({page, host}) => {
  await openExample(page, host, 93);
  await page.keyboard.press("Control+f");
  const dialog = page.getByRole("dialog", {name: "Find"});
  await expect(dialog).toBeVisible();
  await dialog.getByRole("textbox", {name: "Find"}).fill("frankfurt");
  await dialog.getByLabel("Options").selectOption("CASE");
  await dialog.getByRole("button", {name: "Find", exact: true}).click();
  await expect(found(page)).toHaveCount(0);
  await expect(statusMessage(page)).toContainText("was not found");
});

test("ZCL_GG_EX_093 — the standard list status menus sit in the main menu, one open at a time", async ({page, host}) => {
  await openExample(page, host, 93);
  const menubar = page.getByRole("menubar", {name: "Main menu"});
  await expect(menubar.getByRole("menuitem")).toHaveText(["List", "Edit", "System", "Help"]);
  await expect(page.locator(".wb-appbar ~ nav")).toHaveCount(0);

  const list = page.locator('details[data-menu-code="LIST"]');
  const edit = page.locator('details[data-menu-code="EDIT"]');
  await menubar.getByRole("menuitem", {name: "List"}).click();
  await expect(list.getByRole("button", {name: "Save to local file"})).toBeVisible();
  await expect(list.locator("li").first()).toHaveCSS("list-style-type", "none");
  const listBox = await list.locator(".wb-menu-popup").boundingBox();
  const titleBox = await page.locator(".wb-appbar").boundingBox();
  expect(listBox.y).toBeLessThan(titleBox.y);

  // While List is open, pointing at Edit switches to Edit.
  await menubar.getByRole("menuitem", {name: "Edit"}).hover();
  await expect(edit).toHaveAttribute("open", "");
  await expect(list).not.toHaveAttribute("open", "");
  await expect(list.getByRole("button", {name: "Print"})).toBeHidden();

  // Escape closes the menu without reaching the shell as Cancel.
  await page.keyboard.press("Escape");
  await expect(edit).not.toHaveAttribute("open", "");
  await expect(page.locator(".gg-list-line").first()).toBeVisible();

  await menubar.getByRole("menuitem", {name: "Edit"}).click();
  await page.locator(".wb-appbar").click();
  await expect(edit).not.toHaveAttribute("open", "");

  await menubar.getByRole("menuitem", {name: "Edit"}).click();
  await edit.getByRole("button", {name: "Find", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("dialog", {name: "Find"})).toBeVisible();
});

test("ZCL_GG_EX_093 — Find and Find next search the list", async ({page, host}) => {
  await openExample(page, host, 93);
  const toolbar = page.locator(".wb-commandbar");
  await toolbar.getByRole("button", {name: "Find", exact: true}).click();
  await page.waitForLoadState("load");
  const dialog = page.getByRole("dialog", {name: "Find"});
  await dialog.getByRole("textbox", {name: "Find"}).fill("frankfurt");
  await dialog.getByRole("button", {name: "Find"}).click();
  await page.waitForLoadState("load");
  await expect(found(page)).toHaveCount(1);
  await expect(found(page)).toContainText("LH       0400");

  const hits = ["UA       0941", "SQ       0026", "LH       0402", "JL       0407"];
  for (const hit of hits) {
    await toolbar.getByRole("button", {name: "Find next"}).click();
    await page.waitForLoadState("load");
    await expect(found(page)).toContainText(hit);
  }
  await toolbar.getByRole("button", {name: "Find next"}).click();
  await page.waitForLoadState("load");
  await expect(found(page)).toContainText("LH       0400");
  await expect(page.getByRole("navigation", {name: "Search results"})).toBeVisible();
});

test("ZCL_GG_EX_093 — Cancel closes the Find dialog box", async ({page, host}) => {
  await openExample(page, host, 93);
  await page.locator(".wb-commandbar").getByRole("button", {name: "Find", exact: true}).click();
  await page.waitForLoadState("load");
  await page.getByRole("dialog", {name: "Find"}).getByRole("button", {name: "Cancel"}).click();
  await expect(page.getByRole("dialog", {name: "Find"})).toHaveCount(0);
});
