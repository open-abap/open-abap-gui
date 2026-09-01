import {test, expect} from "../fixtures.mjs";

test("transaction links start the real report and dynpro examples", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/`);
  await page.getByRole("link", {name: "ZGG_EX_001"}).click();
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "LIST");
  await expect(page.locator(".gg-list")).toContainText("hello world");

  await page.goto(`${host.baseUrl}/`);
  await page.getByRole("link", {name: "ZGG_EX_058"}).click();
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "DYNPRO");
});

test("the command form accepts /n and normalizes the dynpro tcode", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/`);
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
  await expect(page.getByRole("button", {name: "Return to workbench"})).toBeEnabled();
  await page.keyboard.press("F3");
  await expect(page.locator(".wb-workspace")).toBeVisible();
  await expect(page.locator("[data-page-kind]")).toHaveCount(0);
});

test("F1 reports that field help is still to be built", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/transaction?tcode=ZGG_EX_001`);
  const feedback = page.locator(".wb-status-feedback");
  await expect(feedback).toBeEmpty();
  await page.keyboard.press("F1");
  await expect(feedback).toHaveText("F1: help todo");
  await expect(feedback).not.toHaveClass(/wb-status-error/);
  await expect(page.locator("[data-page-kind]")).toHaveCount(1);
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
  await page.goto(`${host.baseUrl}/`);

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
  expect(message.radius).toBe("999px");
});

test("a status message never changes the height of the status bar", async ({page, host}) => {
  const barHeight = () => page.locator(".wb-statusbar").evaluate((element) => element.getBoundingClientRect().height);

  await page.goto(`${host.baseUrl}/`);
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
    await page.goto(`${host.baseUrl}/`);
    const command = page.getByRole("textbox", {name: "Command"});
    await command.fill("NOT_A_TRANSACTION");
    await command.press("Enter");
    await expect(page.locator(".wb-status-error[role=alert]")).toBeVisible();

    const message = await page.locator(".wb-status-error").evaluate((element) => {
      const style = getComputedStyle(element);
      return {display: style.display, animation: style.animationName, radius: style.borderTopLeftRadius};
    });
    expect(message.display).toBe("block"); // inline-block blockifies as a flex item
    expect(message.animation).toBe("none");
    expect(message.radius).toBe("999px");
  } finally {
    await context.close();
  }
});
