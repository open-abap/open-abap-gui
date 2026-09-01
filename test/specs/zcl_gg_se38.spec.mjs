import {test, expect, dispatch} from "../fixtures.mjs";

test("SE38 displays source and executes through the report runtime", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE38`);
  expect(response?.status()).toBe(200);
  await expect(page.getByText("Subobjects", {exact: true})).toBeVisible();
  await expect(page.locator('[name="gg-radio-SUB"][value="R_SOURCE"]')).toBeChecked();
  await page.locator('input[name="P_PROGRAM"]').fill("ZGG_EX_015");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByRole("status").filter({hasText: "REPORT zgg_ex_015."})).toBeVisible();
  await dispatch(page, {action: "SUBMIT", ucomm: "BACK"});
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await page.getByRole("button", {name: "Execute (F8)", exact: true}).click();
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "SELECTION");
  await expect(page.locator('input[name="P_CARR"]')).toHaveValue("LH");
});

test("SE38 opens the subobject chosen on the initial screen", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE38`);
  expect(response?.status()).toBe(200);
  await page.locator('input[name="P_PROGRAM"]').fill("ZGG_EX_015");
  await page.locator('[name="gg-radio-SUB"][value="R_VARIANTS"]').check();
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0240"]')).toHaveCount(1);
  await expect(page.getByText("DEFAULT", {exact: true})).toBeVisible();
  await expect(page.getByText("1 variant(s) for ZGG_EX_015.", {exact: true})).toBeVisible();
});

test("SE38 distinguishes program states and keeps the entered selection", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE38`);
  expect(response?.status()).toBe(200);
  await page.locator('input[name="P_PROGRAM"]').fill("ZGG_LOCKED");
  await page.locator('[name="gg-radio-SUB"][value="R_ATTRIBUTES"]').check();
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await expect(page.getByRole("alert")).toContainText("You are not authorized to display this program.");
  await expect(page.locator('input[name="P_PROGRAM"]')).toHaveValue("ZGG_LOCKED");
  await expect(page.locator('[name="gg-radio-SUB"][value="R_ATTRIBUTES"]')).toBeChecked();

  await page.locator('input[name="P_PROGRAM"]').fill("ZGG_DRAFT");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0210"]')).toHaveCount(1);
  await expect(page.getByText("INACTIVE", {exact: true})).toBeVisible();
  await dispatch(page, {action: "SUBMIT", ucomm: "BACK"});
  await page.getByRole("button", {name: "Execute (F8)", exact: true}).click();
  await expect(page.getByRole("alert")).toContainText("Program ZGG_DRAFT is inactive; activate it before execution.");
});
