import assert from "node:assert/strict";
import {test, dispatch, clickHelp} from "../fixtures.mjs";

test("ZCL_GG_INTEGRATION_HTML_REPORT — selection, list, and session isolation", async ({page: pageA, browser, host}) => {
  const contextB = await browser.newContext();
  const pageB = await contextB.newPage();

  try {
    await pageA.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_HTML_REPORT`);
    assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "SELECTION");
    const initialSession = await pageA.locator("[data-page-kind]").getAttribute("data-session-id");
    const initialPage = await pageA.locator("[data-page-kind]").getAttribute("data-page-id");
    assert.match(await pageA.getByRole("alert").textContent(), /Enter a carrier/);

    await dispatch(pageA, {action: "HELP", target: "P_CARR"});
    assert.match(await pageA.getByRole("status").textContent(), /Enter a carrier from the integration fixture/);

    await pageA.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_HTML_REPORT`);
    await pageA.locator('[name="P_CARR"]').fill("ZZZ");
    await pageA.getByRole("button", {name: "Continue"}).click();
    await pageA.waitForLoadState("load");
    assert.match(await pageA.getByRole("alert").textContent(), /Unknown carrier/);
    assert.equal(await pageA.locator('[name="P_CARR"]').inputValue(), "ZZZ");
    assert.equal(await pageA.locator('[name="P_CARR"]').getAttribute("aria-invalid"), "true");
    assert.equal(await pageA.locator('[name="P_CARR"]').evaluate((element) => element === document.activeElement), true);

    await pageA.locator('[name="P_CARR"]').fill("LH");
    await pageA.getByRole("button", {name: "Continue"}).click();
    await pageA.waitForLoadState("load");
    assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "LIST");
    assert.match(await pageA.getByText(/LH\/0400/).first().textContent(), /LH\/0400/);
    assert.equal(await pageA.locator('[data-abap-name="CARRID"]').count(), 0);

    await pageA.getByRole("button", {name: "Select line 2"}).click();
    await pageA.waitForLoadState("load");
    assert.match(await pageA.getByText(/Selected flight: LH\/0401/).textContent(), /LH\/0401/);

    await pageA.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_HTML_REPORT`);
    const valueHelpPage = await pageA.locator("[data-page-kind]").getAttribute("data-page-id");
    await clickHelp(pageA, "P_CARR", "Value help for Carrier");
    await pageA.waitForLoadState("load");
    assert.equal(await pageA.locator("[data-page-kind]").getAttribute("data-page-kind"), "SELECTION");
    assert.notEqual(await pageA.locator("[data-page-kind]").getAttribute("data-page-id"), valueHelpPage);
    assert.match(await pageA.getByRole("status").textContent(), /AA/);

    await pageA.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_HTML_REPORT`);
    await pageB.goto(`${host.baseUrl}/ZCL_GG_INTEGRATION_HTML_REPORT`);
    await pageA.locator('[name="P_CARR"]').fill("AA");
    await pageB.locator('[name="P_CARR"]').fill("LH");
    await pageA.getByRole("button", {name: "Continue"}).click();
    await pageB.getByRole("button", {name: "Continue"}).click();
    await pageA.waitForLoadState("load");
    await pageB.waitForLoadState("load");
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
    await contextB.close();
  }
});
