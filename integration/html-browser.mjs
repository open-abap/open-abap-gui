import assert from "node:assert/strict";
import {chromium} from "playwright";
import {createAbapHtmlHostServer} from "../host/abap-html-server.mjs";

const server = createAbapHtmlHostServer();
let browser;
let contextA;
let contextB;
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const base = `http://127.0.0.1:${server.address().port}`;

try {
  try {
    browser = await chromium.launch({headless: true});
  } catch (error) {
    throw new Error("Chromium is not installed; run `npm run install:html-browser`", {cause: error});
  }
  contextA = await browser.newContext();
  contextB = await browser.newContext();
  const pageA = await contextA.newPage();
  const pageB = await contextB.newPage();

  await pageA.goto(`${base}/report`);
  assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "SELECTION");
  const initialSession = await pageA.locator("[data-page-kind]").getAttribute("data-session-id");
  const initialPage = await pageA.locator("[data-page-kind]").getAttribute("data-page-id");
  assert.match(await pageA.getByRole("alert").textContent(), /Enter a carrier/);

  await pageA.getByRole("button", {name: "Field help for Carrier"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.match(await pageA.getByRole("status").textContent(), /Enter a carrier from the integration fixture/);

  await pageA.goto(`${base}/report`);
  await pageA.locator('[name="P_CARR"]').fill("ZZZ");
  await pageA.getByRole("button", {name: "Continue"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.match(await pageA.getByRole("alert").textContent(), /Unknown carrier/);
  assert.equal(await pageA.locator('[name="P_CARR"]').inputValue(), "ZZZ");
  assert.equal(await pageA.locator('[name="P_CARR"]').getAttribute("aria-invalid"), "true");
  assert.equal(await pageA.locator('[name="P_CARR"]').evaluate((element) => element === document.activeElement), true);

  await pageA.locator('[name="P_CARR"]').fill("LH");
  await pageA.getByRole("button", {name: "Continue"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "LIST");
  assert.match(await pageA.getByText(/LH\/0400/).first().textContent(), /LH\/0400/);
  assert.equal(await pageA.locator('[data-abap-name="CARRID"]').count(), 0);

  await pageA.getByRole("button", {name: "Select line 2"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.match(await pageA.getByText(/Selected flight: LH\/0401/).textContent(), /LH\/0401/);

  await pageA.goto(`${base}/report`);
  const valueHelpPage = await pageA.locator("[data-page-kind]").getAttribute("data-page-id");
  await pageA.getByRole("button", {name: "Value help for Carrier"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "SELECTION");
  assert.notEqual(await pageA.locator("[data-page-kind]").getAttribute("data-page-id"), valueHelpPage);
  assert.match(await pageA.getByRole("status").textContent(), /AA/);

  await pageA.goto(`${base}/dynpro`);
  await pageA.getByRole("button", {name: "Field help for P_INPUT"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.match(await pageA.getByRole("status").textContent(), /Help from POH/);

  await pageA.goto(`${base}/dynpro`);
  await pageA.getByRole("button", {name: "Value help for P_INPUT"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.match(await pageA.getByRole("region", {name: "Value help"}).textContent(), /Value from POV/);

  await pageA.goto(`${base}/dynpro`);
  await pageA.getByRole("button", {name: "Back"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.equal(await pageA.locator("[data-screen=\"0000\"]").count(), 1);

  await pageA.goto(`${base}/dynpro`);
  assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "DYNPRO");
  await pageA.locator('[name="P_INPUT"]').fill("AA-0017");
  await pageA.getByRole("button", {name: "Next"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.match(await pageA.getByRole("heading", {name: "Flight result"}).textContent(), /Flight result/);
  assert.equal(await pageA.locator("output").textContent(), "AA-0017");
  await pageA.getByRole("button", {name: "Exit"}).click();
  await pageA.waitForLoadState("networkidle");
  assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "TERMINAL");
  assert.equal(await pageA.locator("form").count(), 0);
  const terminalSession = await pageA.locator("[data-page-kind]").getAttribute("data-session-id");
  const terminalPage = await pageA.locator("[data-page-kind]").getAttribute("data-page-id");
  assert.equal(await pageA.evaluate(async (sessionId) => {
    const response = await fetch(`/session/${encodeURIComponent(sessionId)}`, {method: "DELETE"});
    return response.status;
  }, terminalSession), 204);
  const closedDispatch = await pageA.evaluate(async ({sessionId, pageId}) => {
    const response = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, action: "SUBMIT"}),
    });
    return {status: response.status, body: await response.json()};
  }, {sessionId: terminalSession, pageId: terminalPage});
  assert.equal(closedDispatch.status, 400);
  assert.match(closedDispatch.body.error, /Unknown host session/);

  await pageA.goto(`${base}/report`);
  await pageB.goto(`${base}/report`);
  await pageA.locator('[name="P_CARR"]').fill("AA");
  await pageB.locator('[name="P_CARR"]').fill("LH");
  await pageA.getByRole("button", {name: "Continue"}).click();
  await pageB.getByRole("button", {name: "Continue"}).click();
  await pageA.waitForLoadState("networkidle");
  await pageB.waitForLoadState("networkidle");
  assert.match(await pageA.getByText(/AA\/0017/).first().textContent(), /AA\/0017/);
  assert.doesNotMatch(await pageA.locator("main").textContent(), /LH\/0400/);
  assert.match(await pageB.getByText(/LH\/0400/).first().textContent(), /LH\/0400/);
  assert.doesNotMatch(await pageB.locator("main").textContent(), /AA\/0017/);
  assert.notEqual(
    await pageA.locator("[data-page-kind]").getAttribute("data-session-id"),
    await pageB.locator("[data-page-kind]").getAttribute("data-session-id"),
  );
  assert.notEqual(initialSession, "");
  assert.notEqual(initialPage, "");
} finally {
  await contextA?.close();
  await contextB?.close();
  await browser?.close();
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await server.shutdown();
}

console.log("HTML browser round trips: ok");
