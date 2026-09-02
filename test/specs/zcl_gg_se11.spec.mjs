import {test, expect, dispatch} from "../fixtures.mjs";

test("SE11 displays Dictionary metadata and links table contents", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE11`);
  expect(response?.status()).toBe(200);
  await page.locator('input[name="P_OBJECT_NAME"]').fill("ZSFLIGHT");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("Airline carrier ID", {exact: true})).toBeVisible();
  await expect(page.getByText("ZGG_CARRID_SH", {exact: true})).toBeVisible();
  await expect(page.getByText("Data class APPL0, size category 0, Buffering not allowed, log changes off", {exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Table Contents", exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Change", exact: true})).toBeDisabled();
});

test("SE11 opens a kind-specific screen for each Dictionary object type", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE11`);
  expect(response?.status()).toBe(200);
  await page.selectOption('select[name="P_OBJECT_TYPE"]', "DOMAIN");
  await page.locator('input[name="P_OBJECT_NAME"]').fill("ZGG_CARRID");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0230"]')).toHaveCount(1);
  await expect(page.getByText("Lufthansa", {exact: true})).toBeVisible();
  await expect(page.getByRole("button", {name: "Table Contents", exact: true})).toHaveCount(0);

  await dispatch(page, {action: "SUBMIT", ucomm: "BACK"});
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await page.selectOption('select[name="P_OBJECT_TYPE"]', "SEARCH_HELP");
  await page.locator('input[name="P_OBJECT_NAME"]').fill("ZGG_CARRID_SH");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0250"]')).toHaveCount(1);
  await expect(page.getByText("Display values immediately", {exact: true})).toBeVisible();
});

test("SE11 rejects an unknown name without leaking metadata", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE11`);
  expect(response?.status()).toBe(200);
  await page.selectOption('select[name="P_OBJECT_TYPE"]', "TABLE_TYPE");
  await page.locator('input[name="P_OBJECT_NAME"]').fill("ZSFLIGHT");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await expect(page.getByRole("alert")).toContainText("Dictionary object is unknown or not permitted.");
  await expect(page.locator('select[name="P_OBJECT_TYPE"]')).toHaveValue("TABLE_TYPE");
});
