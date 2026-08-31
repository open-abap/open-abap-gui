import {test, expect} from "../fixtures.mjs";

test("SE01 exposes the five extended-view selection tabs", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=se01`);
  expect(response?.status()).toBe(200);
  await expect(page.getByRole("tab", {name: "Standard requests"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Piece lists"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Client transports"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Delivery transports"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Individual display"})).toBeVisible();
  await expect(page.getByRole("button", {name: "Create", exact: true})).toBeDisabled();
});
