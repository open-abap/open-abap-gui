import {test, expect} from "../fixtures.mjs";

test("SE01 renders the extended-view selection screen", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=se01`);
  expect(response?.status()).toBe(200);
  await expect(page.getByRole("heading", {name: "Transport Organizer (Extended View)"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Display"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Transports"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Piece Lists"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Client"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Deliveries"})).toBeVisible();
  await expect(page.locator('input[name="P_REQUEST"]')).toHaveAttribute("required", "");
  await expect(page.getByRole("button", {name: "Value help for P_REQUEST"})).toBeVisible();
  await expect(page.getByRole("button", {name: "Logs", exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Action Log", exact: true})).toBeVisible();
});
