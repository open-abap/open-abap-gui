import {test, expect} from "../fixtures.mjs";

test("SE11 displays Dictionary metadata and links table contents", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE11`);
  expect(response?.status()).toBe(200);
  await page.locator('input[name="P_OBJECT_NAME"]').fill("ZSFLIGHT");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("CARRID", {exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Table Contents", exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Change", exact: true})).toBeDisabled();
});
