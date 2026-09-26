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
  await expect(page.locator(".wb-toolbar")).toHaveCount(0);
  await expect(page.locator(".wb-appbar")).toHaveCSS("border-top-width", "0px");
  await expect(page.locator(".wb-appbar")).toHaveCSS("border-left-width", "0px");
  await expect(page.locator(".wb-appbar")).toHaveCSS("border-right-width", "0px");
  const commandInputBox = await page.locator(".wb-command-input").boundingBox();
  const appTitleBox = await page.locator(".wb-app-title").boundingBox();
  expect(commandInputBox).not.toBeNull();
  expect(appTitleBox).not.toBeNull();
  expect(appTitleBox.x).toBeCloseTo(commandInputBox.x, 0);
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
  await expect(statusFeedback).toHaveText("");
  await expect(page.locator(".wb-toolbar-button")).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Create"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Open"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Add to favorites"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Edit"})).toHaveCount(0);
  await expect(page.getByRole("button", {name: "Refresh"})).toHaveCount(0);
  await expect(page.getByRole("navigation", {name: "Applications"})).toHaveCount(0);
  const transactions = page.getByRole("navigation", {name: "Transactions"});
  await expect(transactions).toBeVisible();
  await expect(transactions.locator(".wb-app-list > li")).toHaveCount(167);
  const reports = page.getByRole("navigation", {name: "Reports"});
  await expect(reports).toBeVisible();
  await expect(reports.locator(".wb-app-list > li")).toHaveCount(1);
  await expect(reports.getByRole("link", {name: "ZGG_INT_PROGRAM"})).toHaveAttribute(
    "href",
    "/program?name=ZGG_INT_PROGRAM",
  );
  await expect(page.locator(".wb-app-list details")).toHaveCount(0);
  await expect(page.getByText("Workbench", {exact: true})).toBeVisible();
  await expect(page.locator(".wb-app-context")).toHaveCount(0);
  await expect(page.locator(".wb-app-list").getByText("Favorites", {exact: true})).toHaveCount(0);
  await expect(page.locator("svg.wb-icon-sprite symbol#wb-icon-folder-open")).toHaveCount(1);
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
  await expect(page.getByRole("link", {name: "ZGG_INT_HTML_REPORT"})).toHaveAttribute(
    "href",
    "/transaction?tcode=ZGG_INT_HTML_REPORT",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_001"})).toHaveAttribute(
    "href",
    "/transaction?tcode=ZGG_EX_001",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_001"})).toContainText("WRITE literal");
  await expect(page.getByRole("link", {name: "ZGG_EX_058"})).toHaveAttribute(
    "href",
    "/transaction?tcode=ZGG_EX_058",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_066"})).toContainText(
    "Unicode and hostile shell text",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_082"})).toContainText(
    "Variant manager selection screen",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_098"})).toContainText(
    "Composite flight list workbench",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_116"})).toContainText(
    "Two-screen flight editor",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_134"})).toContainText(
    "Document viewer editor",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_147"})).toContainText(
    "SALV selections and events",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_149"})).toContainText(
    "Chart engine graphic fallback",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_150"})).toContainText(
    "Analytics cockpit",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_151"})).toContainText(
    "Full-screen HTML viewer shell",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_152"})).toContainText(
    "Timer lifecycle",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_159"})).toContainText(
    "Multi-month calendar",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_160"})).toContainText(
    "Sibling selection-screen blocks",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_161"})).toContainText(
    "Stacked checkbox parameters",
  );
  await expect(page.getByRole("link", {name: /^ZGG_EX_/})).toHaveCount(160);
  await expect(page.getByRole("link", {name: "ZCL_GG_INTEGRATION_HTML_REPORT"})).toHaveCount(0);
});

test("starts a report without a transaction from the Reports section", async ({page, host}) => {
  await page.goto(host.baseUrl);
  await page.getByRole("navigation", {name: "Reports"}).getByRole("link", {name: "ZGG_INT_PROGRAM"}).click();
  await page.waitForLoadState("load");

  await expect(page.locator(".wb-app-title")).toHaveText("ZGG_INT_PROGRAM");
  await expect(page.getByText("started without a transaction")).toBeVisible();

  const response = await page.goto(`${host.baseUrl}/program?name=ZGG_INT_UNKNOWN`);
  expect(response?.status()).toBe(200);
  await expect(page.locator(".wb-status-feedback")).toHaveText("Unknown program: ZGG_INT_UNKNOWN");
});

test("the splitter resizes the application list by pointer and keyboard", async ({page, host}) => {
  await page.setViewportSize({width: 1280, height: 720});
  await page.goto(`${host.baseUrl}/`);

  const panel = page.locator(".wb-app-panel");
  const splitter = page.getByRole("separator", {name: "Resize application list"});
  await expect(splitter).toHaveAttribute("aria-orientation", "vertical");
  await expect(splitter).toHaveAttribute("aria-valuenow", "305");
  const initial = (await panel.boundingBox()).width;
  expect(initial).toBeCloseTo(305, 0);

  const box = await splitter.boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width / 2 + 120, box.y + box.height / 2, {steps: 5});
  await page.mouse.up();
  expect((await panel.boundingBox()).width).toBeCloseTo(initial + 120, -1);
  const dragged = Number(await splitter.getAttribute("aria-valuenow"));
  expect(dragged).toBeCloseTo(initial + 120, -1);

  await splitter.focus();
  await page.keyboard.press("ArrowLeft");
  await expect(splitter).toHaveAttribute("aria-valuenow", String(dragged - 16));
  await page.keyboard.press("Home");
  await expect(splitter).toHaveAttribute("aria-valuenow", "160");
  expect((await panel.boundingBox()).width).toBeCloseTo(160, 0);

  // The list never grows past the point where the content area stays usable.
  await page.keyboard.press("End");
  const workspace = await page.locator(".wb-workspace").boundingBox();
  expect((await panel.boundingBox()).width).toBeLessThanOrEqual(workspace.width - 240);

  await page.keyboard.press("Home");
  await page.reload();
  await expect(splitter).toHaveAttribute("aria-valuenow", "160");
  expect((await panel.boundingBox()).width).toBeCloseTo(160, 0);
});

test("index keeps the workbench chrome visible in a short viewport", async ({page, host}) => {
  await page.setViewportSize({width: 900, height: 360});
  await page.goto(`${host.baseUrl}/`);

  const viewport = await page.evaluate(() => ({height: window.innerHeight, scrollHeight: document.documentElement.scrollHeight}));
  const topBox = await page.locator(".wb-menubar").boundingBox();
  const workspaceBox = await page.locator(".wb-workspace").boundingBox();
  const appPanelBox = await page.locator(".wb-app-panel").boundingBox();
  const bottomBox = await page.locator(".wb-statusbar").boundingBox();

  expect(viewport.scrollHeight).toBeLessThanOrEqual(viewport.height);
  expect(topBox?.y).toBe(0);
  expect(workspaceBox).not.toBeNull();
  expect(appPanelBox).not.toBeNull();
  expect(bottomBox).not.toBeNull();
  expect(appPanelBox.height).toBeCloseTo(workspaceBox.height - 2, 0);
  expect(bottomBox.y + bottomBox.height).toBeLessThanOrEqual(viewport.height);
});
