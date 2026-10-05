import {test, expect, openExample} from "../fixtures.mjs";

const found = (page) => page.locator(".gg-list-line[data-found]");

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
  await expect(found(page)).toHaveCount(0);
  await expect(page.locator(".gg-message")).toContainText('No further hits for "frankfurt"');
});

test("ZCL_GG_EX_093 — Cancel closes the Find dialog box", async ({page, host}) => {
  await openExample(page, host, 93);
  await page.locator(".wb-commandbar").getByRole("button", {name: "Find", exact: true}).click();
  await page.waitForLoadState("load");
  await page.getByRole("dialog", {name: "Find"}).getByRole("button", {name: "Cancel"}).click();
  await expect(page.getByRole("dialog", {name: "Find"})).toHaveCount(0);
});
