import {test, expect, openExample, submit, expectPageKind, statusMessage} from "../fixtures.mjs";

// Runs the log with the given selection: P_COUNT entries, the message
// displayed like P_LIKE, made long by P_LONG or left out by P_QUIET.
async function runLog(page, host, {count = 3, like = "S", long = false, quiet = false} = {}) {
  await openExample(page, host, 171);
  await expectPageKind(page, "SELECTION");
  await page.locator('[name="P_COUNT"]').fill(String(count));
  await page.locator('[name="P_LIKE"]').fill(like);
  await page.locator('[name="P_LONG"]').setChecked(long);
  await page.locator('[name="P_QUIET"]').setChecked(quiet);
  await submit(page);
  await expectPageKind(page, "LIST");
}

const grid = (page) => page.locator(".gg-alv").first();
const box = async (locator) => {
  const {x, y, width, height} = await locator.boundingBox();
  return {x: Math.round(x), y: Math.round(y), width: Math.round(width), height: Math.round(height)};
};

test("ZCL_GG_EX_171 — the entry count is in the status bar, not above the grid", async ({page, host}) => {
  await runLog(page, host);
  await expect(statusMessage(page)).toHaveText("3 entries listed");
  await expect(statusMessage(page)).toHaveClass(/wb-status-success/);
  await expect(statusMessage(page)).toHaveAttribute("role", "status");
  await expect(statusMessage(page).locator('use[href="#wb-icon-circle-check"]')).toHaveCount(1);
  // A strip: green edge and icon, dark text, a tint that fades into the bar.
  await expect(statusMessage(page)).toHaveCSS("border-left-color", "rgb(16, 126, 62)");
  await expect(statusMessage(page)).toHaveCSS("color", "rgb(29, 45, 62)");
  await expect(statusMessage(page).locator(".wb-icon")).toHaveCSS("color", "rgb(16, 126, 62)");
  await expect(statusMessage(page)).toHaveCSS("background-image", /linear-gradient\(90deg, rgb\(241, 253, 246\).*rgba\(220, 232, 243, 0\)/);
  await expect(page.locator("main")).not.toContainText("entries listed");
  await expect(page.locator(".gg-message, .gg-message-region")).toHaveCount(0);
  await expect(grid(page)).toContainText("Log entry 3");
  // The message sits left, system, client and user stay right.
  const context = page.locator(".wb-statusbar .wb-status-context");
  await expect(context).toContainText("System:");
  await expect(context).toContainText("Client:");
  await expect(context).toContainText("User:");
  expect((await box(statusMessage(page))).x).toBeLessThan((await box(context)).x);
});

test("ZCL_GG_EX_171 — an empty log shows its grid and 0 entries listed", async ({page, host}) => {
  await runLog(page, host, {count: 0});
  await expect(statusMessage(page)).toHaveText("0 entries listed");
  await expect(grid(page)).toBeVisible();
  await expect(grid(page)).not.toContainText("Log entry");
  await expect(page.locator("main")).not.toContainText("entries listed");
});

for (const item of [
  {like: "I", kind: "wb-status-info", icon: "info-circle", role: "status"},
  {like: "W", kind: "wb-status-warning", icon: "alert-triangle", role: "alert"},
  {like: "E", kind: "wb-status-error", icon: "alert-octagon", role: "alert"},
]) {
  test(`ZCL_GG_EX_171 — DISPLAY LIKE ${item.like} styles the status bar message`, async ({page, host}) => {
    await runLog(page, host, {like: item.like});
    await expect(statusMessage(page)).toHaveText("3 entries listed");
    await expect(statusMessage(page)).toHaveClass(new RegExp(item.kind));
    await expect(statusMessage(page)).toHaveAttribute("role", item.role);
    await expect(statusMessage(page).locator(`use[href="#wb-icon-${item.icon}"]`)).toHaveCount(1);
    // S displayed like E is still S: the list is shown.
    await expect(grid(page)).toContainText("Log entry 1");
  });
}

test("ZCL_GG_EX_171 — a message leaves the grid's position and height alone", async ({page, host}) => {
  await runLog(page, host, {quiet: true});
  await expect(statusMessage(page)).toHaveText("");
  const quietGrid = await box(grid(page));
  const quietContent = await box(page.locator(".wb-runtime-content"));
  const quietBar = await box(page.locator(".wb-statusbar"));

  await runLog(page, host);
  await expect(statusMessage(page)).toHaveText("3 entries listed");
  expect(await box(grid(page))).toEqual(quietGrid);
  expect(await box(page.locator(".wb-runtime-content"))).toEqual(quietContent);
  expect(await box(page.locator(".wb-statusbar"))).toEqual(quietBar);
});

test("ZCL_GG_EX_171 — a long message is cut short but never hides the status context", async ({page, host}) => {
  await page.setViewportSize({width: 900, height: 720});
  await runLog(page, host, {quiet: true});
  const quietBar = await box(page.locator(".wb-statusbar"));
  const quietGrid = await box(grid(page));

  await runLog(page, host, {long: true});
  const message = statusMessage(page);
  await expect(message).toContainText("3 entries listed; the log holds every message");
  const fullText = await message.textContent();
  await expect(message).toHaveAttribute("title", fullText);
  expect(await box(page.locator(".wb-statusbar"))).toEqual(quietBar);

  const geometry = await page.evaluate(() => {
    const bar = document.querySelector(".wb-statusbar").getBoundingClientRect();
    const text = document.querySelector("#wb-status-message");
    const context = document.querySelector(".wb-status-context").getBoundingClientRect();
    return {
      clipped: text.scrollWidth > text.clientWidth,
      ellipsis: getComputedStyle(text).textOverflow,
      messageRight: text.getBoundingClientRect().right,
      contextLeft: context.left,
      contextRight: context.right,
      contextWidth: context.width,
      barRight: bar.right,
    };
  });
  expect(geometry.clipped).toBe(true);
  expect(geometry.ellipsis).toBe("ellipsis");
  expect(geometry.messageRight).toBeLessThanOrEqual(geometry.contextLeft);
  expect(geometry.contextWidth).toBeGreaterThan(0);
  expect(geometry.contextRight).toBeLessThanOrEqual(geometry.barRight);

  // A clipped message can be focused and then shows its full text above the
  // bar, without moving the bar or the grid.
  await expect(message).toHaveAttribute("tabindex", "0");
  await message.focus();
  const opened = await message.evaluate((element) => ({
    whiteSpace: getComputedStyle(element).whiteSpace,
    clipped: element.scrollWidth > element.clientWidth,
    bottom: element.getBoundingClientRect().bottom,
    barTop: document.querySelector(".wb-statusbar").getBoundingClientRect().top,
  }));
  expect(opened.whiteSpace).toBe("normal");
  expect(opened.clipped).toBe(false);
  expect(opened.bottom).toBeLessThanOrEqual(opened.barTop);
  expect(await box(page.locator(".wb-statusbar"))).toEqual(quietBar);
  expect(await box(grid(page))).toEqual(quietGrid);
});

test("ZCL_GG_EX_171 — a short message is not made focusable", async ({page, host}) => {
  await runLog(page, host);
  await expect(statusMessage(page)).not.toHaveAttribute("tabindex", /.*/);
});

test("ZCL_GG_EX_171 — the status bar stays at the bottom while the grid scrolls", async ({page, host}) => {
  await runLog(page, host, {count: 200});
  await expect(statusMessage(page)).toHaveText("200 entries listed");
  const viewport = page.viewportSize();
  const bar = page.locator(".wb-statusbar");
  const before = await box(bar);
  expect(before.y + before.height).toBeLessThanOrEqual(viewport.height);
  expect(before.y + before.height).toBeGreaterThan(viewport.height - 20);
  // Scroll every scrolling box of the page to its end.
  await page.evaluate(() => {
    document.querySelectorAll("main, main *").forEach((element) => {
      if (element.scrollHeight > element.clientHeight) element.scrollTop = element.scrollHeight;
    });
  });
  await expect(page.getByText("Log entry 200", {exact: true})).toBeInViewport();
  expect(await box(bar)).toEqual(before);
  await expect(statusMessage(page)).toBeInViewport();
});

test("ZCL_GG_EX_171 — the status bar stays on one line at the bottom of a phone screen", async ({page, host}) => {
  await page.setViewportSize({width: 375, height: 667});
  await runLog(page, host, {count: 200, long: true});
  const bar = page.locator(".wb-statusbar");
  await expect(bar).toBeInViewport();
  await page.mouse.wheel(0, 20000);
  await expect(bar).toBeInViewport();
  await expect(page.locator(".wb-status-context")).toBeInViewport();
  const {height} = await box(bar);
  expect(height).toBeLessThanOrEqual(26);
});

test("ZCL_GG_EX_171 — no message outlives the page it was sent for", async ({page, host}) => {
  await runLog(page, host);
  await expect(statusMessage(page)).toHaveText("3 entries listed");
  await page.locator(".wb-command-button--back").click();
  await page.waitForLoadState("load");
  await expectPageKind(page, "SELECTION");
  await expect(statusMessage(page)).toHaveText("");

  await page.locator('[name="P_QUIET"]').check();
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(statusMessage(page)).toHaveText("");
});
