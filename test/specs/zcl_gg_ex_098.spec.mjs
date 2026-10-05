import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_098 — filters, sorts, and refreshes a composite flight list", async ({page, host}) => {
  await openExample(page, host, 98);
  await expect(page.locator(".gg-list-line")).toHaveCount(4);
  // Each function writes the next detail list from the program's table.
  await submit(page, "Filter");
  await expect(page.locator("body")).toContainText("Flights: FILTERED");
  await expect(page.locator(".gg-list-line")).toHaveCount(2);
  await expect(page.locator(".gg-list-line").filter({hasText: /^\s*LH/})).toHaveCount(2);
  await submit(page, "Sort");
  await expect(page.locator("body")).toContainText("Flights: SORTED");
  await expect(page.locator(".gg-list-line").first()).toContainText("240");
  await submit(page, "Refresh");
  await expect(page.locator("body")).toContainText("Flights: FLIGHTS");
  await expect(page.locator(".gg-list-line")).toHaveCount(4);
});
