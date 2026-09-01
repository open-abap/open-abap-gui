import {test, expect, clickHelp} from "../fixtures.mjs";

test("SE16 generates a typed selection screen and executes a bounded query", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE16`);
  expect(response?.status()).toBe(200);
  await page.getByRole("button", {name: "Table Contents", exact: true}).click();
  await expect(page.locator('[data-screen="0150"]')).toHaveCount(1);
  await expect(page.getByText("CARRID - Airline carrier ID", {exact: true})).toBeVisible();
  await expect(page.getByText("PRICE - Flight price", {exact: true})).toBeVisible();
  await expect(page.locator('select[name="P_T1_OP1"]')).toHaveValue("EQ");
  await expect(page.locator('input[name="P_T1_OUT1"]')).not.toBeChecked();
  await page.locator('input[name="P_T1_MAX"]').fill("2");
  await page.getByRole("button", {name: "Execute", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("2 of 5 rows returned; hard maximum reached.", {exact: true})).toBeVisible();
  await expect(page.getByRole("columnheader", {name: "Airline carrier ID", exact: true})).toBeVisible();
  await expect(page.getByText("2026-01-01", {exact: true})).toBeVisible();
  await expect(page.getByText("New York", {exact: true})).toBeVisible();
});

test("SE16 answers F4 on a criterion from the field's domain", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE16`);
  expect(response?.status()).toBe(200);
  await page.getByRole("button", {name: "Table Contents", exact: true}).click();
  await clickHelp(page, "P_T1_LOW1", "Value help for P_T1_LOW1");
  const help = page.getByRole("region", {name: "Value help"});
  await expect(help.locator("li")).toHaveText(["AA", "LH", "SQ"]);
});

test("SE16 keeps criteria after a typed validation error", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE16`);
  expect(response?.status()).toBe(200);
  await page.getByRole("button", {name: "Table Contents", exact: true}).click();
  await page.locator('input[name="P_T1_LOW2"]').fill("AB");
  await page.getByRole("button", {name: "Execute", exact: true}).click();
  await expect(page.locator('[data-screen="0150"]')).toHaveCount(1);
  await expect(page.getByRole("alert")).toContainText("CONNID is a NUMC field and only accepts digits.");
  await expect(page.locator('input[name="P_T1_LOW2"]')).toHaveValue("AB");
});
