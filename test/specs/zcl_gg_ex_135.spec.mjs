import {test, expect, openExample, submit} from "../fixtures.mjs";
import {readFile} from "node:fs/promises";

test("ALV standard export and print functions operate on the visible grid", async ({page, host}) => {
  await openExample(page, host, 135);
  const grid = page.locator('[data-control-kind="ALV_GRID"]');
  let download = page.waitForEvent("download");
  await grid.getByRole("button", {name: "Export to file", exact: true}).click();
  const csv = await download;
  expect(csv.suggestedFilename()).toBe("table.csv");
  const text = await readFile(await csv.path(), "utf8");
  expect(text).toContain('"Lufthansa"');
  expect(text).toContain('"Occupied"');
  expect(text).not.toContain("Row selection");

  download = page.waitForEvent("download");
  await grid.getByRole("button", {name: "XML export", exact: true}).click();
  const xml = await download;
  expect(xml.suggestedFilename()).toBe("table.xml");
  expect(await readFile(await xml.path(), "utf8")).toContain("<cell>Lufthansa</cell>");

  await page.evaluate(() => {
    window.printCalls = 0;
    window.print = () => { window.printCalls++; };
  });
  await grid.getByRole("button", {name: "Print", exact: true}).click();
  expect(await page.evaluate(() => window.printCalls)).toBe(1);
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("3 flights, 5 columns");
});

test("ZCL_GG_EX_135 — shows a grid from its field catalog", async ({page, host}) => {
  await openExample(page, host, 135);
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("thead th")).toHaveText(["Row selection", "Airline", "Name", "Flight", "Capacity", "Occupied"]);
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("h2")).toHaveText("Flight capacity");
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("tbody tr")).toHaveCount(3);
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator('tbody td[data-fieldname="CARRNAME"]').first()).toHaveAttribute("data-emphasize", "C300");
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("tfoot")).toContainText("550");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("3 flights, 5 columns");
  await submit(page, "Capacity column");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Capacity column hidden");
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("thead th")).toHaveCount(5);
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("tbody tr").first().locator("td")).toHaveCount(5);
  await submit(page, "Striped rows");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Plain rows");
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("table")).toHaveAttribute("data-zebra", "false");
});
