import {test, expect, openExample, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_44 — renders PF-STATUS and excluded commands`, async ({page, host}) => {
  await openExample(page, host, 44);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-status")).toContainText("LIST");
  await expect(page.getByRole("button", {name: "DEL"})).toBeDisabled();
  await expect(page.locator(".gg-list")).toContainText("body");
  const iconBar = page.locator(".wb-toolbar");
  await expect(iconBar.getByRole("button")).toHaveCount(2);
  await expect(iconBar.locator(".wb-toolbar-separator")).toHaveCount(1);
  await expect(iconBar.getByRole("button").nth(0)).toHaveAccessibleName("Refresh");
  await expect(iconBar.getByRole("button").nth(1)).toHaveAccessibleName("Print");
  await expect(iconBar.getByRole("button", {name: "Refresh"})).toHaveAttribute("data-ucomm", "REFR");
  await expect(iconBar.getByRole("button", {name: "Refresh"}).locator("use")).toHaveAttribute("href", "#wb-icon-refresh");
  await expect(iconBar.getByRole("button", {name: "Print"}).locator("use")).toHaveAttribute("href", "#wb-icon-printer");
  await iconBar.getByRole("button", {name: "Refresh"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line")).toHaveText(["body", "refreshed"]);
});

test(`ZCL_GG_EX_44 — the status activates the standard print command`, async ({page, host}) => {
  await openExample(page, host, 44);

  const commandBar = page.locator(".wb-commandbar");
  await expect(commandBar.locator('[title="Print"]')).toBeEnabled();
  await expect(commandBar.locator('[title="Save"]')).toBeDisabled();
  await expect(commandBar.locator('[title="Find"]')).toBeDisabled();

  await commandBar.locator('[title="Print"]').click();
  await page.waitForLoadState("networkidle");
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["body", "printed"]);
});

test(`ZCL_GG_EX_44 — inactive and excluded commands are rejected without staling the page`, async ({page, host}) => {
  await openExample(page, host, 44);
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");

  const response = await page.evaluate(async ({sessionId, pageId}) => {
    const result = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "COMMAND", ucomm: "SAVE"}),
    });
    return {status: result.status, body: await result.json()};
  }, {sessionId, pageId});
  expect(response.status).toBe(400);
  expect(response.body.error).toMatch(/not active/);
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-id", pageId);

  const excluded = await page.evaluate(async ({sessionId, pageId}) => {
    const result = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "COMMAND", ucomm: "DEL"}),
    });
    return {status: result.status, body: await result.json()};
  }, {sessionId, pageId});
  expect(excluded.status).toBe(400);
  expect(excluded.body.error).toMatch(/not active/);
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-id", pageId);
});
