import {test, expect} from "../fixtures.mjs";

test("workbench exposes a read-only converter preview with diagnostics before source", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/`);
  await page.getByRole("menuitem", {name: "Tools"}).click();

  await expect(page).toHaveURL(/\/converter\/preview$/);
  await expect(page.getByRole("heading", {name: "Converter Preview"})).toBeVisible();
  await page.getByLabel("Repository program").selectOption("ZGG_EX_015");
  await page.getByLabel("Target class name (required)").fill("ZCL_CV_PREVIEW_015");
  await page.getByLabel("Transaction code (optional)").fill("ZCVP015");
  await page.getByRole("button", {name: "Inspect diagnostics"}).click();

  await expect(page.getByRole("heading", {name: "Diagnostics"})).toBeVisible();
  await expect(page.getByText("selection text for P_CARR", {exact: false})).toBeVisible();
  await expect(page.locator("[data-generated-source]")).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Show generated source"})).toBeVisible();
  await expect(page.locator("[data-save-disabled]")).toContainText("unavailable");
  await expect(page.getByRole("button", {name: "Save generated class"})).toHaveCount(0);
  await expect(page.getByText("Parameter: supported", {exact: false})).toBeVisible();

  await page.getByRole("button", {name: "Show generated source"}).click();
  await expect(page.locator("[data-generated-source]")).toContainText(
    "CLASS zcl_cv_preview_015 DEFINITION",
  );
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("link", {name: "Download generated class"}).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe("zcl_cv_preview_015.clas.abap");
});

test("workbench requires explicit collision confirmation before generated source", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/converter/preview`);
  await page.getByLabel("Repository program").selectOption("ZGG_EX_015");
  await page.getByLabel("Target class name (required)").fill("ZCL_GG_SYSTEM_REPOSITORY");
  await page.getByLabel("Transaction code (optional)").fill("ZCVP015C");
  await page.getByRole("button", {name: "Inspect diagnostics"}).click();

  await expect(page.getByText("GGCONV-E602", {exact: false})).toBeVisible();
  await expect(page.getByRole("button", {name: "Show generated source"})).toHaveCount(0);

  await page.getByLabel(/explicitly confirm replacing/).check();
  await page.getByRole("button", {name: "Inspect diagnostics"}).click();
  await expect(page.getByRole("button", {name: "Show generated source"})).toBeVisible();
});
