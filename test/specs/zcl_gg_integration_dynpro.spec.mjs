import assert from "node:assert/strict";
import {test} from "../fixtures.mjs";

test("ZCL_GG_INTEGRATION_DYNPRO — help, value help, and screen round trips", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  await page.getByRole("button", {name: "Field help for P_INPUT"}).click();
  await page.waitForLoadState("load");
  assert.match(await page.getByRole("status").textContent(), /Help from POH/);

  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  await page.getByRole("button", {name: "Value help for P_INPUT"}).click();
  await page.waitForLoadState("load");
  assert.match(await page.getByRole("region", {name: "Value help"}).textContent(), /Value from POV/);

  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  await page.getByRole("button", {name: "Back"}).click();
  await page.waitForLoadState("load");
  assert.equal(await page.locator('[data-screen="0000"]').count(), 1);

  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  assert.equal(await page.locator("[data-page-kind]").getAttribute("data-page-kind"), "DYNPRO");
  await page.locator('[name="P_INPUT"]').fill("AA-0017");
  await page.getByRole("button", {name: "Next"}).click();
  await page.waitForLoadState("load");
  assert.match(await page.getByRole("heading", {name: "Flight result"}).textContent(), /Flight result/);
  assert.equal(await page.locator("output").textContent(), "AA-0017");
  await page.getByRole("button", {name: "Exit"}).click();
  await page.waitForLoadState("load");
  assert.equal(await page.locator("[data-page-kind]").getAttribute("data-page-kind"), "TERMINAL");
  assert.equal(await page.locator(".wb-runtime-content form").count(), 0);
  const terminalSession = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const terminalPage = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  assert.equal(await page.evaluate(async (sessionId) => {
    const response = await fetch(`/session/${encodeURIComponent(sessionId)}`, {method: "DELETE"});
    return response.status;
  }, terminalSession), 204);
  const closedDispatch = await page.evaluate(async ({sessionId, pageId}) => {
    const response = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "SUBMIT"}),
    });
    return {status: response.status, body: await response.json()};
  }, {sessionId: terminalSession, pageId: terminalPage});
  assert.equal(closedDispatch.status, 400);
  assert.match(closedDispatch.body.error, /Unknown host session/);
});
