import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_145 — sorts, filters and totals a SALV table", async ({page, host}) => {
  await openExample(page, host, 145);
  const table = page.getByRole("table", {name: "Occupied seats per airline"});
  await expect(table.locator("tbody tr.gg-grid-row")).toHaveCount(4);
  await expect(table).not.toContainText("0945");
  await expect(table.locator("tr.gg-grid-subtotal")).toHaveCount(3);
  await expect(table.locator("tfoot")).toContainText("790");
});
