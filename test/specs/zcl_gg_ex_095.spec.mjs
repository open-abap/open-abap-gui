import {test, expect, openExample} from "../fixtures.mjs";
import {readFile} from "node:fs/promises";

const saveAs = async (page, format, filename) => {
  await page.getByRole("menuitem", {name: "List"}).click();
  await page.getByRole("button", {name: "Save to local file"}).click();
  await page.waitForLoadState("load");
  const dialog = page.getByRole("dialog", {name: "Save list in file"});
  await dialog.getByRole("radio", {name: format}).check();
  await dialog.getByRole("textbox", {name: "File name"}).fill(filename);
  const download = page.waitForEvent("download");
  await dialog.getByRole("button", {name: "Save"}).click();
  return download;
};

test("ZCL_GG_EX_095 — Save to local file writes the list as a spreadsheet", async ({page, host}) => {
  await openExample(page, host, 95);
  const download = await saveAs(page, "Spreadsheet", "carriers.xls");
  expect(download.suggestedFilename()).toBe("carriers.xls");
  const content = await readFile(await download.path(), "utf8");
  expect(content).toBe("ID\tAirline\tCurrency\r\nLH\tLufthansa\tEUR\r\nUA\tUnited Airlines\tUSD\r\nSQ\tSingapore Airlines\tSGD\r\n");
  await expect(page.locator(".gg-message")).toContainText("The list was saved as carriers.xls");
});

test("ZCL_GG_EX_095 — unconverted keeps the columns of the list", async ({page, host}) => {
  await openExample(page, host, 95);
  const download = await saveAs(page, "Unconverted", "carriers.txt");
  const content = await readFile(await download.path(), "utf8");
  expect(content.split("\r\n")[1]).toMatch(/^LH\s+Lufthansa\s+EUR$/);
});
