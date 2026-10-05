import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_105 — shows the program's table in a table control", async ({page, host}) => {
  await openExample(page, host, 105);
  const table = page.locator("[data-table-control]");
  await expect(table.locator("thead th")).toHaveText(["Airline", "Flight", "From", "To"]);
  const rows = table.locator("tbody tr");
  await expect(rows.nth(0)).toContainText("AA0017New YorkSan Francisco");
  await expect(rows.nth(2)).toContainText("UA0941FrankfurtSan Francisco");
  // Every column is output only, and the lines below the table's three are empty.
  await expect(table.locator("input")).toHaveCount(0);
  await expect(rows.nth(3)).toHaveText("");
});
