import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_106 — renders editable table cells", async ({page, host}) => {
  await openExample(page, host, 106);
  const table = page.locator('[data-table-control]');
  await expect(table.locator("input")).toHaveCount(6);
  await expect(table.locator('[name="gg-cell-TC_FLIGHTS-CARRID-1"]')).toHaveValue("AA");
  await expect(table.locator('[name="gg-cell-TC_FLIGHTS-CITY-2"]')).toHaveValue("Berlin");
});

