import {test, expect} from "../fixtures.mjs";

test("index renders the open-abap workbench shell", async ({page, host}) => {
  const response = await page.goto(`${host.baseUrl}/`);

  expect(response?.status()).toBe(200);
  await expect(page.getByRole("menubar", {name: "Main menu"})).toBeVisible();
  await expect(page.getByRole("button", {name: "Minimize"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Maximize"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Close"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Go"})).toHaveCount(0);
  await expect(page.getByRole("textbox", {name: "Command"})).toBeVisible();
  const commandButtons = page.locator(".wb-commandbar").getByRole("button");
  await expect(commandButtons).toHaveCount(11);
  const commandButtonNames = [
    "Save",
    "Back",
    "Exit",
    "Cancel",
    "Print",
    "Find",
    "Find next",
    "First page",
    "Previous page",
    "Next page",
    "Last page",
  ];
  for (const [index, name] of commandButtonNames.entries()) {
    await expect(commandButtons.nth(index)).toHaveAccessibleName(name);
  }
  const commandIconRefs = [
    "device-floppy",
    "arrow-back-up",
    "logout",
    "circle-x",
    "printer",
    "search",
    "search-plus",
    "arrow-bar-to-up",
    "file-arrow-up",
    "file-arrow-down",
    "arrow-bar-to-down",
  ];
  for (const [index, iconRef] of commandIconRefs.entries()) {
    await expect(commandButtons.nth(index).locator("use")).toHaveAttribute("href", `#wb-icon-${iconRef}`);
  }
  await expect(commandButtons.nth(0)).toBeEnabled();
  await expect(commandButtons.nth(1)).toBeEnabled();
  await expect(commandButtons.nth(3)).toBeEnabled();
  await expect(commandButtons.nth(1)).toHaveClass(/wb-command-button--back/);
  await expect(commandButtons.nth(2)).toHaveClass(/wb-command-button--exit/);
  await expect(commandButtons.nth(3)).toHaveClass(/wb-command-button--cancel/);
  await expect(page.getByRole("navigation", {name: "Application tree"})).toBeVisible();
  await expect(page.getByText("Workbench", {exact: true})).toBeVisible();
  await expect(page.locator("svg.wb-icon-sprite symbol#wb-icon-folder-open")).toHaveCount(1);
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
