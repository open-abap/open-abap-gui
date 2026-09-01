import {test, expect} from "../fixtures.mjs";

test("SE01 renders the extended-view selection screen", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=se01`);
  expect(response?.status()).toBe(200);
  await expect(page.getByRole("heading", {name: "Transport Organizer (Extended View): Display"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Display"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Transports"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Piece Lists"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Client"})).toBeVisible();
  await expect(page.getByRole("tab", {name: "Deliveries"})).toBeVisible();
  await expect(page.locator('input[name="P_REQUEST"]')).toHaveAttribute("required", "");
  await expect(page.getByRole("button", {name: "Value help for P_REQUEST"})).toBeHidden();
  await page.locator('input[name="P_REQUEST"]').focus();
  await expect(page.getByRole("button", {name: "Value help for P_REQUEST"})).toBeVisible();
  await expect(page.getByRole("button", {name: "Logs", exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Action Log", exact: true})).toBeVisible();
});

test("SE01 keeps each tab's criteria and validates its number convention", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE01`);
  expect(response?.status()).toBe(200);
  await page.locator('input[name="P_REQUEST"]').fill("DEVKD00001");
  await page.getByRole("tab", {name: "Transports"}).click();
  await expect(page.locator('[data-screen="0110"]')).toHaveCount(1);
  await expect(page.getByText("Request numbers on this tab follow the <SID>K9nnnnn convention.", {exact: true})).toBeVisible();

  await page.locator('input[name="P_STD_REQUEST"]').fill("DEVKO00001");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0110"]')).toHaveCount(1);
  await expect(page.getByRole("alert")).toContainText("does not follow the <SID>K9nnnnn convention for standard requests.");

  await page.locator('input[name="P_STD_REQUEST"]').fill("DEVK900001");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("Dictionary inspection task", {exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Release", exact: true})).toBeDisabled();

  await page.getByRole("button", {name: "Properties", exact: true}).click();
  await expect(page.locator('[data-screen="0210"]')).toHaveCount(1);
  await expect(page.getByText("DEV -> QAS", {exact: true})).toBeVisible();
  await expect(page.getByText("STANDARD", {exact: true})).toBeVisible();
});

test("SE01 displays a delivery transport from the individual tab", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE01`);
  expect(response?.status()).toBe(200);
  await page.locator('input[name="P_REQUEST"]').fill("DEVKD00001");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("Delivery transport", {exact: true})).toBeVisible();
  await expect(page.getByText("Delivery of the flight fixtures", {exact: true})).toBeVisible();
});
