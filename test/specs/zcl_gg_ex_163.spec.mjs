import {test, expect, openExample, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_163 — renders a SALV table after casting a column to cl_salv_column_table", async ({page, host}) => {
  await openExample(page, host, 163);
  await expectPageKind(page, "DYNPRO");
  const table = page.getByRole("table", {name: "Event status"});
  await expect(table).toBeVisible();
  await expect(table.locator('th[data-fieldname="TRAFFIC_LIGHT"]')).toHaveCount(1);
  await expect(table.locator("tbody tr")).toHaveCount(2);
  await expect(table).toContainText("BUS2032");
});
