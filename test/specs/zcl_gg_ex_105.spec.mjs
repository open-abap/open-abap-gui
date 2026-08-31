import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_105 — renders a read-only table control", async ({page, host}) => {
  await openExample(page, host, 105);
  const table = page.locator('[data-table-control]');
  await expect(table).toHaveAttribute("data-selection-mode", "SINGLE");
  await expect(table.locator("tbody tr")).toHaveCount(3);
  await expect(table.locator("tbody tr").nth(0)).toContainText("AAFrankfurt");
  await expect(table.locator("tbody tr").nth(1)).toContainText("LHBerlin");
  await expect(table.locator("input")).toHaveCount(0);
});

