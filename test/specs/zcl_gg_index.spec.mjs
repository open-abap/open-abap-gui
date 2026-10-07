import {test, expect} from "../fixtures.mjs";
import {readdir} from "node:fs/promises";

test("main menu holds System and Help; System > Status shows the session", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/`);

  const menubar = page.getByRole("menubar", {name: "Main menu"});
  await expect(menubar.getByRole("menuitem")).toHaveText(["System", "Help"]);
  const help = menubar.getByRole("menuitem", {name: "Help"});
  await expect(help).toHaveAttribute("href", "https://open-abap.org");
  await expect(help).toHaveAttribute("target", "_blank");

  const system = menubar.getByRole("menuitem", {name: "System"});
  const statusItem = page.getByRole("menuitem", {name: "Status..."});
  await expect(statusItem).toBeHidden();
  await system.click();
  await expect(system).toHaveAttribute("aria-expanded", "true");
  await expect(statusItem).toBeFocused();
  // A click elsewhere closes the menu.
  await page.locator(".wb-appbar").click();
  await expect(statusItem).toBeHidden();

  await system.click();
  await statusItem.click();
  await expect(statusItem).toBeHidden();
  const dialog = page.getByRole("dialog", {name: "System: Status"});
  await expect(dialog).toBeVisible();
  for (const group of ["Usage data", "System data", "Host data"]) {
    await expect(dialog.getByRole("heading", {name: group})).toBeVisible();
  }
  await expect(dialog.locator("dt", {hasText: "Client"}).locator("+ dd")).toHaveText(/\S/);
  await expect(dialog.locator("dt", {hasText: "System date"}).locator("+ dd")).toHaveText(/^\d{2}\.\d{2}\.\d{4}$/);
  await expect(dialog.getByRole("button", {name: "Close system status"})).toBeFocused();

  // Escape closes the dialog without reaching the shell's Cancel.
  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(system).toBeFocused();
  await expect(page).toHaveURL(`${host.baseUrl}/`);
});

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
  const transactionLinks = await transactions.getByRole("link").all();
  expect(transactionLinks.length).toBeGreaterThanOrEqual(177);
  const transactionUrls = await Promise.all(transactionLinks.map(link => link.getAttribute("href")));
  expect(new Set(transactionUrls).size).toBe(transactionUrls.length);
  const reports = page.getByRole("navigation", {name: "Reports"});
  await expect(reports).toBeVisible();
  await expect(reports.locator(".wb-app-list > li")).toHaveCount(2);
  await expect(reports.getByRole("link", {name: "ZGG_INT_PROGRAM"})).toHaveAttribute(
    "href",
    "/program?name=ZGG_INT_PROGRAM",
  );
  await expect(page.locator(".wb-app-list details")).toHaveCount(0);
  await expect(page.getByText("Workbench", {exact: true})).toBeVisible();
  await expect(page.locator(".wb-app-context")).toHaveCount(0);
  await expect(page.locator(".wb-app-list").getByText("Favorites", {exact: true})).toHaveCount(0);
  // The sprite carries the icons the page shows, such as the file icon of each application.
  await expect(page.locator("svg.wb-icon-sprite symbol#wb-icon-file-code")).toHaveCount(1);
  await expect(page.locator("svg.wb-icon-sprite symbol#wb-icon-folder-open")).toHaveCount(0);
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
    "Document viewer and editor",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_147"})).toContainText(
    "SALV selections and events",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_149"})).toContainText(
    "Chart engine",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_150"})).toContainText(
    "Analytics cockpit",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_151"})).toContainText(
    "HTML viewer with SAPEVENT",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_152"})).toContainText(
    "Timer",
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
  await expect(page.getByRole("link", {name: "ZGG_EX_162"})).toContainText(
    "ALV grid on the default screen",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_163"})).toContainText(
    "SALV column cast to column table",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_164"})).toContainText(
    "Radio USER-COMMAND with MODIF ID select-options",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_165"})).toContainText(
    "Read a text file with READ DATASET",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_166"})).toContainText(
    "Tabbed selection screen",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_167"})).toContainText(
    "Listbox values from VRM_SET_VALUES",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_168"})).toContainText(
    "Select-options defaulting to today",
  );
  await expect(page.getByRole("link", {name: "ZGG_EX_169"})).toContainText(
    "Selection tabs with icons",
  );
  const committedExamples = (await readdir(new URL("../../examples/", import.meta.url)))
    .filter(name => /^zcl_gg_ex_\d{3}\.clas\.abap$/.test(name))
    .map(name => name.match(/\d{3}/)[0]);
  const exampleUrls = await page.getByRole("link", {name: /^ZGG_EX_/}).evaluateAll(
    links => links.map(link => link.getAttribute("href")),
  );
  for (const id of committedExamples) {
    expect(exampleUrls).toContain(`/transaction?tcode=ZGG_EX_${id}`);
  }
  expect(new Set(exampleUrls).size).toBe(exampleUrls.length);
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
