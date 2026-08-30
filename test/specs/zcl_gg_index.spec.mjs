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
  await expect(page.locator(".wb-appbar")).toHaveCSS("margin-top", "0px");
  await expect(page.locator(".wb-commandbar")).toHaveCSS("padding-left", "18px");
  await expect(page.locator(".wb-commandbar")).toHaveCSS("padding-right", "0px");
  await expect(page.locator(".wb-appbar")).toHaveCSS("margin-left", "0px");
  await expect(page.locator(".wb-appbar")).toHaveCSS("margin-right", "0px");
  await expect(page.locator(".wb-toolbar")).toHaveCSS("margin-left", "0px");
  await expect(page.locator(".wb-toolbar")).toHaveCSS("margin-right", "0px");
  await expect(page.locator(".wb-appbar")).toHaveCSS("border-top-width", "0px");
  await expect(page.locator(".wb-appbar")).toHaveCSS("border-left-width", "0px");
  await expect(page.locator(".wb-appbar")).toHaveCSS("border-right-width", "0px");
  await expect(page.locator(".wb-toolbar")).toHaveCSS("border-left-width", "0px");
  await expect(page.locator(".wb-toolbar")).toHaveCSS("border-right-width", "0px");
  const commandInputBox = await page.locator(".wb-command-input").boundingBox();
  const appTitleBox = await page.locator(".wb-app-title").boundingBox();
  const firstToolbarButtonBox = await page.locator(".wb-toolbar-button").first().boundingBox();
  expect(commandInputBox).not.toBeNull();
  expect(appTitleBox).not.toBeNull();
  expect(firstToolbarButtonBox).not.toBeNull();
  expect(appTitleBox.x).toBeCloseTo(commandInputBox.x, 0);
  expect(firstToolbarButtonBox.x).toBeCloseTo(commandInputBox.x, 0);
  const statusContext = page.locator(".wb-status-context");
  await expect(statusContext).toContainText("System:\u00a0");
  await expect(statusContext).toContainText("Client:\u00a0");
  await expect(statusContext).toContainText("User:\u00a0");
  const statusBarBox = await page.locator(".wb-statusbar").boundingBox();
  const statusContextBox = await statusContext.boundingBox();
  expect(statusBarBox).not.toBeNull();
  expect(statusContextBox).not.toBeNull();
  expect(statusContextBox.x + statusContextBox.width).toBeCloseTo(
    statusBarBox.x + statusBarBox.width - 11,
    0,
  );
  await expect(page.getByText("Ready", {exact: true})).toHaveCount(0);
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
  for (const index of commandButtonNames.keys()) {
    await expect(commandButtons.nth(index)).toBeDisabled();
  }
  const saveBox = await commandButtons.nth(0).boundingBox();
  expect(saveBox).not.toBeNull();
  await page.mouse.move(saveBox.x + saveBox.width / 2, saveBox.y + saveBox.height / 2);
  await page.mouse.down();
  await expect(commandButtons.nth(0)).toHaveCSS("transform", "none");
  await expect(commandButtons.nth(0)).toHaveCSS("background-color", "rgba(0, 0, 0, 0)");
  await expect(commandButtons.nth(0)).toHaveCSS("box-shadow", "none");
  await page.mouse.up();
  await expect(commandButtons.nth(1)).toHaveClass(/wb-command-button--back/);
  await expect(commandButtons.nth(2)).toHaveClass(/wb-command-button--exit/);
  await expect(commandButtons.nth(3)).toHaveClass(/wb-command-button--cancel/);
  const statusFeedback = page.locator(".wb-status-feedback");
  await expect(statusFeedback).toHaveText("");
  await commandButtons.nth(0).dispatchEvent("click");
  await expect(statusFeedback).toHaveText("");
  await page.locator(".wb-toolbar-button").nth(0).click();
  await expect(statusFeedback).toHaveText("Create pressed");
  await expect(page.getByRole("navigation", {name: "Application tree"})).toBeVisible();
  await expect(page.getByText("Workbench", {exact: true})).toBeVisible();
  await expect(page.locator(".wb-app-context")).toHaveCount(0);
  await expect(page.locator(".wb-tree").getByText("Favorites", {exact: true})).toHaveCount(0);
  await expect(page.locator("svg.wb-icon-sprite symbol#wb-icon-folder-open")).toHaveCount(1);
  await expect(page.locator('a[href="/ZCL_GG_DB_HELPER"] svg use[href="#wb-icon-database"]')).toHaveCount(1);
  await expect(page.locator('.wb-logo-only .wb-welcome-art')).toHaveCount(1);
  await expect(page.locator('.wb-logo-only .wb-welcome-art')).toHaveAttribute("aria-label", "open-abap");
  await expect(page.locator('.wb-logo-mark')).toHaveAttribute("viewBox", "0 0 108 108");
  await expect(page.locator('.wb-logo-mark linearGradient#wb-logo-edge')).toHaveCount(1);
  await expect(page.locator('.wb-logo-mark g')).toHaveAttribute("transform", "translate(-56.318804,-55.73065)");
  await expect(page.locator('.wb-logo-mark path')).toHaveCount(6);
  await expect(page.locator('.wb-logo-mark path[fill="#24466f"]')).toHaveCount(1);
  const contentBox = await page.locator(".wb-content").boundingBox();
  const logoBox = await page.locator(".wb-logo-only .wb-welcome-art").boundingBox();
  expect(contentBox).not.toBeNull();
  expect(logoBox).not.toBeNull();
  expect(logoBox.x).toBeCloseTo(contentBox.x, 0);
  expect(logoBox.y).toBeCloseTo(contentBox.y, 0);
  expect(logoBox.width).toBeCloseTo(contentBox.width, 0);
  expect(logoBox.height).toBeCloseTo(contentBox.height, 0);
  await expect(page.getByRole("link", {name: "ZCL_GG_DB_HELPER"})).toHaveAttribute(
    "href",
    "/ZCL_GG_DB_HELPER",
  );
  await expect(page.getByRole("link", {name: "ZCL_GG_INTEGRATION_HTML_REPORT"}).first()).toHaveAttribute(
    "href",
    "/ZCL_GG_INTEGRATION_HTML_REPORT",
  );
});

test("index keeps the workbench chrome visible in a short viewport", async ({page, host}) => {
  await page.setViewportSize({width: 900, height: 360});
  await page.goto(`${host.baseUrl}/`);

  const viewport = await page.evaluate(() => ({height: window.innerHeight, scrollHeight: document.documentElement.scrollHeight}));
  const topBox = await page.locator(".wb-menubar").boundingBox();
  const workspaceBox = await page.locator(".wb-workspace").boundingBox();
  const treeBox = await page.locator(".wb-tree-panel").boundingBox();
  const bottomBox = await page.locator(".wb-statusbar").boundingBox();

  expect(viewport.scrollHeight).toBeLessThanOrEqual(viewport.height);
  expect(topBox?.y).toBe(0);
  expect(workspaceBox).not.toBeNull();
  expect(treeBox).not.toBeNull();
  expect(bottomBox).not.toBeNull();
  expect(treeBox.height).toBeCloseTo(workspaceBox.height - 2, 0);
  expect(bottomBox.y + bottomBox.height).toBeLessThanOrEqual(viewport.height);
});
