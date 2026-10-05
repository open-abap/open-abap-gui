import assert from "node:assert/strict";
import {test, dispatch, clickHelp} from "../fixtures.mjs";

test("ZCL_GG_INTEGRATION_DYNPRO — help, value help, and screen round trips", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  await dispatch(page, {action: "HELP", target: "P_INPUT"});
  assert.match(await page.getByRole("status").textContent(), /Help from POH/);

  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  await clickHelp(page, "P_INPUT", "Value help for P_INPUT");
  await page.waitForLoadState("load");
  assert.match(await page.getByRole("region", {name: "Value help"}).textContent(), /Value from POV/);

  // Screen 0 ends the transaction the workbench started, so the workbench shows.
  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  await dispatch(page, {action: "SUBMIT", ucomm: "BACK"});
  assert.equal(await page.locator("#wb-app-panel").count(), 1);
  assert.equal(await page.locator("[data-page-kind]").count(), 0);

  await page.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_DYNPRO`);
  assert.equal(await page.locator("[data-page-kind]").getAttribute("data-page-kind"), "DYNPRO");
  await page.locator('[name="P_INPUT"]').fill("AA-0017");
  await page.getByRole("button", {name: "Next", exact: true}).click();
  await page.waitForLoadState("load");
  assert.match(await page.getByRole("heading", {name: "Flight result"}).textContent(), /Flight result/);
  assert.equal(await page.locator("output").textContent(), "AA-0017");
  const endedSession = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const endedPage = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  // LEAVE PROGRAM ends the transaction: the workbench shows and the session is closed.
  await page.locator("#gg-main-content").getByRole("button", {name: "Exit"}).click();
  await page.waitForLoadState("load");
  assert.equal(await page.locator("#wb-app-panel").count(), 1);
  assert.equal(await page.locator("[data-page-kind]").count(), 0);
  assert.equal(await page.evaluate(async (sessionId) => {
    const response = await fetch(`/session/${encodeURIComponent(sessionId)}`, {method: "DELETE"});
    return response.status;
  }, endedSession), 204);
  const closedDispatch = await page.evaluate(async ({sessionId, pageId}) => {
    const response = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "SUBMIT"}),
    });
    return {status: response.status, body: await response.json()};
  }, {sessionId: endedSession, pageId: endedPage});
  assert.equal(closedDispatch.status, 400);
  assert.match(closedDispatch.body.error, /Unknown host session/);
});
