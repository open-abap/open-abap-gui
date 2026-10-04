import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_135 — shows a grid from its field catalog", async ({page, host}) => {
  await openExample(page, host, 135);
  await expect(page.locator('[data-control-kind="ALV_GRID"]').locator("thead th")).toHaveText(["Select", "Airline", "Name", "Flight", "Capacity", "Occupied"]);
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
