import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_137 — sorts and filters the grid", async ({page, host}) => {
  await openExample(page, host, 137);
  const flights = page.locator('[data-control-kind="ALV_GRID"]').locator('tbody td[data-fieldname="CONNID"]');
  await expect(flights).toHaveText(["0402", "0941", "0400", "0010"]);
  await submit(page, "Sort direction");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Sorted by occupied seats, ascending");
  await expect(flights).toHaveText(["0010", "0400", "0941", "0402"]);
  await submit(page, "Only LH");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Airline LH, 2 flight(s) filtered out");
  await expect(flights).toHaveText(["0400", "0402"]);
  await submit(page, "All airlines");
  await expect(flights).toHaveCount(4);
});
