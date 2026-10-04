import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_144 — shows a SALV table with column texts", async ({page, host}) => {
  await openExample(page, host, 144);
  const table = page.getByRole("table", {name: "Flights"});
  await expect(table.locator("thead th")).toHaveText(["Airline", "Flight", "From", "To", "Occupied"]);
  await expect(table.locator("tbody tr")).toHaveCount(3);
  await expect(table).toContainText("San Francisco");
});
