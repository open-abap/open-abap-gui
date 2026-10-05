import {test, expect, openExample, submit} from "../fixtures.mjs";

const lines = (page) => page.locator(".gg-list-line");

test("ZCL_GG_EX_085 — a refresh replaces its detail list", async ({page, host}) => {
  await openExample(page, host, 85);
  await expect(lines(page)).toHaveText(["Flight LH 0400, Frankfurt to New York"]);
  for (let refresh = 1; refresh <= 3; refresh++) {
    await submit(page, "Refresh");
    await expect(lines(page)).toHaveText([`Free seats ${12 - refresh}`, `Refreshed ${refresh} times`]);
  }
  // sy-lsind = 1 kept one detail list, so Back reaches the basic list at once.
  await page.locator(".wb-commandbar").getByRole("button", {name: "Back", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(lines(page)).toHaveText(["Flight LH 0400, Frankfurt to New York"]);
});

test("ZCL_GG_EX_085 — an old page is stale after a refresh", async ({page, host}) => {
  await openExample(page, host, 85);
  const oldPage = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  await submit(page, "Refresh");
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const response = await page.evaluate(async ({sessionId, oldPage}) => {
    const result = await fetch("/dispatch", {method: "POST", headers: {"content-type": "application/json"}, body: JSON.stringify({session_id: sessionId, page_id: oldPage, action: "COMMAND", ucomm: "REFRESH"})});
    return {status: result.status, body: await result.json()};
  }, {sessionId, oldPage});
  expect(response.status).toBe(409);
  expect(response.body.error).toMatch(/stale/i);
});
