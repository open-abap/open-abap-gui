import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_061 — distinguishes enabled, inactive, and excluded commands", async ({page, host}) => {
  await openExample(page, host, 61);
  const toolbar = page.locator(".wb-toolbar");
  await expect(toolbar.getByRole("button", {name: "Enabled"})).toBeEnabled();
  await expect(toolbar.getByRole("button", {name: "Inactive"})).toBeDisabled();
  await expect(toolbar.getByRole("button", {name: "Excluded"})).toBeDisabled();

  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const response = await page.evaluate(async ({sessionId, pageId}) => {
    const result = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "COMMAND", ucomm: "EXCLUDED"}),
    });
    return {status: result.status, body: await result.json()};
  }, {sessionId, pageId});
  expect(response.status).toBe(400);
  expect(response.body.error).toMatch(/not active/);
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-id", pageId);
});
