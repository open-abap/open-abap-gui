import {test, expect} from "../fixtures.mjs";

test("SE38 displays source and executes through the report runtime", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/transaction?tcode=SE38`);
  expect(response?.status()).toBe(200);
  await expect(page.getByText("Variant", {exact: true})).toHaveCount(0);
  await expect(page.getByText("Subobject", {exact: true})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "With Variant", exact: true})).toHaveCount(0);
  await expect(page.locator('button[name="gg_ucomm"][value="BACK"]')).toHaveCount(0);
  await page.locator('input[name="P_PROGRAM"]').fill("ZGG_EX_015");
  await page.getByRole("button", {name: "Display", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByRole("status").filter({hasText: "REPORT zgg_ex_015."})).toBeVisible();
  await page.getByRole("button", {name: "Back", exact: true}).click();
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await page.getByRole("button", {name: "Execute (F8)", exact: true}).click();
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "SELECTION");
  await expect(page.locator('input[name="P_CARR"]')).toHaveValue("LH");
});
