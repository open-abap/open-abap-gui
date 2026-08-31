import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_135 — renders ALV field-catalog columns", async ({page, host}) => {
  await openExample(page, host, 135);
  await expect(page.locator('[data-control-kind="ALV_GRID"] table th')).toContainText(["Select", "Carrier", "Flight", "Seats"]);
  await expect(page.locator('[data-control-kind="ALV_GRID"] tbody tr')).toHaveCount(3);
});

