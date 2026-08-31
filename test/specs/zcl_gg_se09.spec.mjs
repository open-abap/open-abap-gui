import {test, expect} from "../fixtures.mjs";

test("SE09 displays the server-owned transport hierarchy", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE09`);
  expect(response?.status()).toBe(200);
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "DYNPRO");
  await expect(page.locator("[data-screen=\"0100\"]")).toHaveCount(1);
  await page.locator('input[name="P_REQUEST"]').fill("DEVK900001");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("Dictionary inspection task", {exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Create", exact: true})).toBeDisabled();
});
