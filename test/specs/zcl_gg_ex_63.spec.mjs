import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_63 — rejects PF6 and accepts declared PF5", async ({page, host}) => {
  await openExample(page, host, 63);
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const rejected = await page.evaluate(async ({sessionId, pageId}) => {
    const result = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "PF", pf_key: 6}),
    });
    return {status: result.status, body: await result.json()};
  }, {sessionId, pageId});
  expect(rejected.status).toBe(400);
  expect(rejected.body.error).toMatch(/not active/);
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-id", pageId);
  await dispatch(page, {action: "PF", pf_key: 5});
  await expect(page.locator(".gg-list-line")).toHaveText(["body", "pf5"]);
});

