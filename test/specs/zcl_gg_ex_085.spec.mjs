import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_085 — refresh is server-owned and old pages are stale", async ({page, host}) => {
  await openExample(page, host, 85);
  const oldPage = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  await submit(page, "Refresh");
  await expect(page.locator(".gg-list-line").last()).toHaveText("refreshed from server state");
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const response = await page.evaluate(async ({sessionId, oldPage}) => {
    const result = await fetch("/dispatch", {method: "POST", headers: {"content-type": "application/json"}, body: JSON.stringify({session_id: sessionId, page_id: oldPage, action: "COMMAND", ucomm: "REFRESH"})});
    return {status: result.status, body: await result.json()};
  }, {sessionId, oldPage});
  expect(response.status).toBe(409);
  expect(response.body.error).toMatch(/stale/i);
});
