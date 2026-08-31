import {test, expect} from "../fixtures.mjs";

test("SE16 executes a bounded typed table query", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE16`);
  expect(response?.status()).toBe(200);
  await page.locator('input[name="P_MAX_ROWS"]').fill("2");
  await page.getByRole("button", {name: "Table Contents", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("2 of 5 rows returned; hard maximum reached.", {exact: true})).toBeVisible();
  await expect(page.locator("tbody tr")).toHaveCount(8);
  await expect(page.getByText("New York", {exact: true})).toBeVisible();
});
