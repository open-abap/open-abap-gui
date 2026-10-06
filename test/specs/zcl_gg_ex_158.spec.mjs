import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_158 — lists each airline with its flights below it", async ({page, host}) => {
  await openExample(page, host, 158);
  const table = page.getByRole("table", {name: "Flights by airline"});
  await expect(table.locator("thead tr").nth(0).locator("th")).toHaveText(["Airline", "Name"]);
  await expect(table.locator("thead tr").nth(1).locator("th")).toHaveText(["Flight", "From", "To", "Occupied"]);

  const rows = table.locator("tbody tr");
  await expect(rows).toHaveCount(5);
  await expect(rows.nth(0)).toHaveAttribute("data-level", "1");
  await expect(rows.nth(0)).toContainText("Lufthansa");
  await expect(rows.nth(1)).toHaveAttribute("data-level", "2");
  await expect(rows.nth(1)).toContainText("0400");
  await expect(rows.nth(2)).toContainText("0402");
  await expect(rows.nth(3)).toContainText("United Airlines");
  await expect(rows.nth(4)).toContainText("San Francisco");

  // Only the aggregated column is totalled.
  await expect(table.locator("tfoot td[data-total]")).toHaveText(["630"]);
  const toggle = rows.nth(0).getByRole("button", {name: "Toggle LH"});
  await toggle.click();
  await expect(rows.nth(1)).toBeHidden();
  await expect(rows.nth(2)).toBeHidden();
  await expect(rows.nth(4)).toBeVisible();
  await toggle.press("Enter");
  await expect(rows.nth(1)).toBeVisible();
  await expect(toggle).toHaveAttribute("aria-expanded", "true");
});
