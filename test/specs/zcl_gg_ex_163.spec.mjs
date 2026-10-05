import {test, expect, openExample, expectPageKind, expectWorkbench} from "../fixtures.mjs";

test("ZCL_GG_EX_163 — renders a SALV table after casting a column to cl_salv_column_table", async ({page, host}) => {
  await openExample(page, host, 163);
  await expectPageKind(page, "DYNPRO");
  await expect(page.getByRole("heading", {name: "Event status"})).toBeVisible();
  // The program sets no list header, so the table has no caption of its own.
  const table = page.locator(".gg-alv table");
  await expect(table).toBeVisible();
  await expect(table.locator('th[data-fieldname="TRAFFIC_LIGHT"]')).toHaveCount(1);
  await expect(table.locator("tbody tr")).toHaveCount(2);
  await expect(table).toContainText("BUS2032");
});

test("ZCL_GG_EX_163 — Back leaves the screen", async ({page, host}) => {
  await openExample(page, host, 163);
  await page.getByRole("button", {name: "Back", exact: true}).click();
  await page.waitForLoadState("load");
  await expectWorkbench(page);
});
