import {test, expect, workbenchUrl} from "../fixtures.mjs";

test("transaction links start the real report and dynpro examples", async ({page, host}) => {
  await page.goto(workbenchUrl(host));
  await page.getByRole("link", {name: "ZGG_EX_001"}).click();
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "LIST");
  await expect(page.locator(".gg-list")).toContainText("hello world");

  await page.goto(workbenchUrl(host));
  await page.getByRole("link", {name: "ZGG_EX_058"}).click();
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "DYNPRO");
});

test("the command form accepts /n and normalizes the dynpro tcode", async ({page, host}) => {
  await page.goto(workbenchUrl(host));
  const command = page.getByRole("textbox", {name: "Command"});
  await expect(command).toHaveAttribute("name", "command");
  await expect(command.locator("xpath=ancestor::form")).toHaveAttribute("action", "/transaction");
  await command.fill("/nzgg_ex_058");
  await command.press("Enter");
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "DYNPRO");
  await expect(page.getByRole("textbox", {name: "Command"})).toHaveValue("");
});

test("F3 activates the green Back button", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/transaction?tcode=ZGG_EX_001`);
  // The list has the standard list status, so Back is the list's own.
  await expect(page.locator(".wb-commandbar").getByRole("button", {name: "Back", exact: true})).toBeEnabled();
  await page.keyboard.press("F3");
  await expect(page.locator(".wb-workspace")).toBeVisible();
  await expect(page.locator("[data-page-kind]")).toHaveCount(0);
});

test("F1 stays silent until a focused field exposes real help", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/transaction?tcode=ZGG_EX_001`);
  const feedback = page.locator(".wb-status-feedback");
  await expect(feedback).toBeEmpty();
  await page.keyboard.press("F1");
  await expect(feedback).toBeEmpty();
  await expect(page.locator("[data-page-kind]")).toHaveCount(1);
});

test("the status bar paints each message type in its own colour", async ({page, host}) => {
  await page.goto(workbenchUrl(host));
  const feedback = page.locator(".wb-status-feedback");

  // An error arrives from the server; the rest are announced by the shell.
  const command = page.getByRole("textbox", {name: "Command"});
  await command.fill("NOT_A_TRANSACTION");
  await command.press("Enter");
  await expect(feedback).toHaveClass(/wb-status-error/);

  const paint = (type) => feedback.evaluate((element, messageType) => {
    element.classList.remove("wb-status-error", "wb-status-warning", "wb-status-success", "wb-status-info");
    element.classList.add(messageType);
    element.textContent = messageType;
    const style = getComputedStyle(element);
    return {text: style.color, edge: style.borderLeftColor};
  }, type).then((painted) => {
    expect(painted.text).toBe("rgb(29, 45, 62)");
    return painted.edge;
  });

  const colors = {
    "wb-status-error": await paint("wb-status-error"),
    "wb-status-warning": await paint("wb-status-warning"),
    "wb-status-success": await paint("wb-status-success"),
    "wb-status-info": await paint("wb-status-info"),
  };
  // The type colour is the edge's and the icon's; the text stays dark.
  expect(colors["wb-status-error"]).toBe("rgb(187, 0, 0)");
  expect(colors["wb-status-warning"]).toBe("rgb(233, 115, 12)");
  expect(colors["wb-status-success"]).toBe("rgb(16, 126, 62)");
  expect(colors["wb-status-info"]).toBe("rgb(10, 110, 209)");
  expect(new Set(Object.values(colors)).size).toBe(4);
});

test("a valid command replaces the old host session", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/transaction?tcode=ZGG_EX_001`);
  const oldSession = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const oldPage = await page.locator("[data-page-kind]").getAttribute("data-page-id");

  await page.getByRole("textbox", {name: "Command"}).fill("/nZGG_EX_002");
  await page.getByRole("textbox", {name: "Command"}).press("Enter");
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "LIST");
  await expect(page.locator("[data-page-kind]")).not.toHaveAttribute("data-session-id", oldSession);
  await expect(page.getByRole("textbox", {name: "Command"})).toHaveValue("");

  const stale = await page.evaluate(async ({sessionId, pageId}) => {
    const response = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "SUBMIT"}),
    });
    return {status: response.status, body: await response.json()};
  }, {sessionId: oldSession, pageId: oldPage});
  expect(stale.status).toBe(400);
  expect(stale.body.error).toMatch(/Unknown host session/);
});

test("a bare /n closes the host session and returns to the menu", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/transaction?tcode=ZGG_EX_001`);
  const oldSession = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const oldPage = await page.locator("[data-page-kind]").getAttribute("data-page-id");

  const command = page.getByRole("textbox", {name: "Command"});
  await command.fill("/n");
  await command.press("Enter");
  await expect(page.locator(".wb-workspace")).toBeVisible();
  await expect(page.locator("[data-page-kind]")).toHaveCount(0);
  await expect(page.locator(".wb-status-error")).toHaveCount(0);
  await expect(page.getByRole("link", {name: "ZGG_EX_001"})).toBeVisible();

  const closed = await page.evaluate(async ({sessionId, pageId}) => {
    const response = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "SUBMIT"}),
    });
    return {status: response.status, body: await response.json()};
  }, {sessionId: oldSession, pageId: oldPage});
  expect(closed.status).toBe(400);
  expect(closed.body.error).toMatch(/Unknown host session/);
});

test("invalid commands clear the command field and leave the old session open", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/transaction?tcode=ZGG_EX_001`);
  const oldSession = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const oldPage = await page.locator("[data-page-kind]").getAttribute("data-page-id");

  const command = page.getByRole("textbox", {name: "Command"});
  await command.fill("/nUNKNOWN");
  const responsePromise = page.waitForResponse((response) =>
    response.url().endsWith("/transaction") && response.request().method() === "POST");
  await command.press("Enter");
  const response = await responsePromise;
  expect(response.status()).toBe(200);
  await expect(page.locator(".wb-status-error[role=alert]")).toContainText("Unknown transaction code");
  await expect(command).toHaveValue("");

  const stillOpen = await page.evaluate(async ({sessionId, pageId}) => {
    const response = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "SUBMIT"}),
    });
    return response.status;
  }, {sessionId: oldSession, pageId: oldPage});
  expect(stillOpen).toBe(200);
});

test("invalid workbench commands render in the bottom message bar", async ({page, host}) => {
  await page.goto(workbenchUrl(host));

  const command = page.getByRole("textbox", {name: "Command"});
  await command.fill("NOT_A_TRANSACTION");
  const responsePromise = page.waitForResponse((response) =>
    response.url().endsWith("/transaction") && response.request().method() === "POST");
  await command.press("Enter");
  const response = await responsePromise;

  expect(response.status()).toBe(200);
  await expect(page.locator(".wb-status-error[role=alert]")).toContainText("Unsupported command");
  await expect(page.locator("#wb-command-error")).toHaveCount(0);
  await expect(command).toHaveValue("");
  await expect(command).toBeEditable();

  const message = await page.locator(".wb-status-error").evaluate((element) => {
    const style = getComputedStyle(element);
    return {animation: style.animationName, duration: style.animationDuration, radius: style.borderTopLeftRadius};
  });
  expect(message.animation).toBe("wb-status-pop");
  expect(message.duration).toBe("0.26s");
  expect(message.radius).toBe("0px");
});

test("a status message never changes the height of the status bar", async ({page, host}) => {
  const barHeight = () => page.locator(".wb-statusbar").evaluate((element) => element.getBoundingClientRect().height);

  await page.goto(workbenchUrl(host));
  const idle = await barHeight();

  const command = page.getByRole("textbox", {name: "Command"});
  await command.fill("NOT_A_TRANSACTION");
  await command.press("Enter");
  await expect(page.locator(".wb-status-error[role=alert]")).toBeVisible();
  expect(await barHeight()).toBe(idle);

  // A message far wider than the bar is ellipsized, never wrapped onto a
  // second line that would push the workspace up.
  await page.locator(".wb-status-feedback").evaluate((element) => {
    element.textContent = `Unknown transaction code: ${"VERY_LONG_TRANSACTION_NAME_".repeat(12)}`;
  });
  expect(await barHeight()).toBe(idle);
  const overflow = await page.locator(".wb-status-feedback").evaluate((element) => ({
    clipped: element.scrollWidth > element.clientWidth,
    ellipsis: getComputedStyle(element).textOverflow,
    wrap: getComputedStyle(element).whiteSpace,
  }));
  expect(overflow.clipped).toBe(true);
  expect(overflow.ellipsis).toBe("ellipsis");
  expect(overflow.wrap).toBe("nowrap");
});

test("a status message stays prominent without motion", async ({browser, host}) => {
  const context = await browser.newContext({reducedMotion: "reduce"});
  const page = await context.newPage();
  try {
    await page.goto(workbenchUrl(host));
    const command = page.getByRole("textbox", {name: "Command"});
    await command.fill("NOT_A_TRANSACTION");
    await command.press("Enter");
    await expect(page.locator(".wb-status-error[role=alert]")).toBeVisible();

    const message = await page.locator(".wb-status-error").evaluate((element) => {
      const style = getComputedStyle(element);
      return {display: style.display, animation: style.animationName, radius: style.borderTopLeftRadius};
    });
    expect(message.display).toBe("block");
    expect(message.animation).toBe("none");
    expect(message.radius).toBe("0px");
  } finally {
    await context.close();
  }
});

// In a browser tab /o opens the new session in a new tab, like SAP GUI opens a
// new window; each tab keeps its own program, and /i closes the tab again.
test("/o opens a session in a new tab and /i closes it", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/transaction?tcode=SE16`);
  await page.getByRole("button", {name: "Table Contents", exact: true}).click();
  await expect(page.locator('[data-screen="0150"]')).toHaveCount(1);
  await page.locator('input[name="P_T1_MAX"]').fill("2");

  const command = page.getByRole("textbox", {name: "Command"});
  const popupPromise = page.waitForEvent("popup");
  await command.fill("/ose11");
  await command.press("Enter");
  const popup = await popupPromise;
  await popup.waitForLoadState();
  await expect(popup.locator("#wb-page-title")).toContainText("Dictionary");
  await expect(popup.locator('meta[name="gg-window"]')).not.toHaveAttribute("content", "W0");
  await expect(command).toHaveValue("");

  // The first tab's program carries on, with its own screen.
  await expect(page.locator('[data-screen="0150"]')).toHaveCount(1);
  await page.getByRole("button", {name: "Execute", exact: true}).click();
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.getByText("2 of 5 rows returned; hard maximum reached.", {exact: true})).toBeVisible();

  const closed = popup.waitForEvent("close");
  const popupCommand = popup.getByRole("textbox", {name: "Command"});
  await popupCommand.fill("/i");
  await popupCommand.press("Enter");
  await closed;

  // With one session left, End Session is not offered.
  await page.goto(workbenchUrl(host));
  await page.getByRole("menuitem", {name: "System"}).click();
  await expect(page.getByRole("menuitem", {name: "End Session"})).toBeDisabled();
});

// A link on a page of a second tab starts its program in that tab's session.
test("System > Create Session opens a tab whose links stay in its session", async ({page, host}) => {
  await page.goto(workbenchUrl(host));
  await page.getByRole("menuitem", {name: "System"}).click();
  const popupPromise = page.waitForEvent("popup");
  await page.getByRole("menuitem", {name: "Create Session"}).click();
  const popup = await popupPromise;
  await popup.waitForLoadState();
  await expect(popup.locator("#wb-app-panel")).toBeVisible();
  const window = await popup.locator('meta[name="gg-window"]').getAttribute("content");
  expect(window).not.toBe("W0");

  await popup.getByRole("link", {name: "SE16"}).click();
  await expect(popup).toHaveURL(new RegExp(`[?&]gg_window=${window}(&|$)`));
  await expect(popup.locator('meta[name="gg-window"]')).toHaveAttribute("content", window);
  await popup.getByRole("button", {name: "Table Contents", exact: true}).click();
  await expect(popup.locator('[data-screen="0150"]')).toHaveCount(1);

  // The tab was opened from a page, so the browser lets /i close it.
  const closed = popup.waitForEvent("close");
  const popupCommand = popup.getByRole("textbox", {name: "Command"});
  await popupCommand.fill("/i");
  await popupCommand.press("Enter");
  await closed;
});
