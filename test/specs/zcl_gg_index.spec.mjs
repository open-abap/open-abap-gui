import {test, expect} from "../fixtures.mjs";

test("index renders the open-abap workbench shell", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/`);

  expect(response?.status()).toBe(200);
  await expect(page.getByRole("menubar", {name: "Main menu"})).toBeVisible();
  await expect(page.getByRole("button", {name: "Minimize"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Maximize"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Close"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Go"})).toBeVisible();
  await expect(page.getByRole("textbox", {name: "Command"})).toBeVisible();
  await expect(page.getByRole("navigation", {name: "Application tree"})).toBeVisible();
  await expect(page.getByText("Workbench", {exact: true})).toBeVisible();
  await expect(page.locator("svg.wb-icon-sprite symbol#wb-icon-folder-open")).toHaveCount(1);
  await expect(page.locator('button[aria-label="Go"] svg use[href="#wb-icon-player-play"]')).toHaveCount(1);
  await expect(page.locator('a[href="/ZCL_GG_DB_HELPER"] svg use[href="#wb-icon-database"]')).toHaveCount(1);
  await expect(page.locator('.wb-content-icon svg use[href="#wb-icon-device-desktop"]')).toHaveCount(1);
  await expect(page.getByRole("link", {name: "ZCL_GG_DB_HELPER"})).toHaveAttribute(
    "href",
    "/ZCL_GG_DB_HELPER",
  );
  await expect(page.getByRole("link", {name: "ZCL_GG_INTEGRATION_HTML_REPORT"}).first()).toHaveAttribute(
    "href",
    "/ZCL_GG_INTEGRATION_HTML_REPORT",
  );
});
