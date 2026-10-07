import {test, expect, openExample, submit} from "../fixtures.mjs";

const toolbar = (page) => page.locator(".wb-toolbar");
const lines = (page) => page.locator(".gg-list-line");

test("ZCL_GG_EX_044 — the excluded function is not offered", async ({page, host}) => {
  await openExample(page, host, 44);
  await expect(toolbar(page).getByRole("button")).toHaveText(["Refresh"]);
  await expect(page.getByRole("button", {name: "Delete"})).toHaveCount(0);
  // The page shows the functions of the status, never its name.
  await expect(page.locator(".gg-list-status")).toHaveCount(0);

  await submit(page, "Refresh");
  await expect(lines(page)).toHaveText(["Bookings of flight LH 0400, refreshed 1 times"]);
});

test("ZCL_GG_EX_044 — the code of an excluded function is refused", async ({page, host}) => {
  await openExample(page, host, 44);
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const response = await page.evaluate(async ({sessionId, pageId}) => {
    const result = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "COMMAND", ucomm: "DEL"}),
    });
    return {status: result.status, body: await result.json()};
  }, {sessionId, pageId});
  expect(response.status).toBe(400);
  expect(response.body.error).toMatch(/not active/);
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-id", pageId);
});
