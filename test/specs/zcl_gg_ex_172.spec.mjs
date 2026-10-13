import {test, expect, openExample, expectPageKind, statusMessage} from "../fixtures.mjs";

// The function module the report calls does not exist here, so the step
// fails with CX_SY_DYN_CALL_ILLEGAL_FUNC, which has no text of its own. The
// HTTP handler answers it with the exception's class and attributes.
const EXPLANATION = "CX_SY_DYN_CALL_ILLEGAL_FUNC (FUNCTION = RPY_TRANSACTION_READ)";

test("ZCL_GG_EX_172 — a step posted as JSON fails with the missing function module", async ({page, host}) => {
  await openExample(page, host, 172);
  await expectPageKind(page, "SELECTION");
  const program = page.locator("[data-page-kind]");
  const response = await page.context().request.post(`${host.baseUrl}/dispatch`, {
    headers: {"content-type": "application/json"},
    data: {
      session_id: await program.getAttribute("data-session-id"),
      page_id: await program.getAttribute("data-page-id"),
      action: "SUBMIT",
      values: [{name: "P_TCODE", value: "SE38"}],
    },
  });

  expect(response.status()).toBe(500);
  expect(await response.json()).toEqual({valid: false, error: EXPLANATION});
});

test("ZCL_GG_EX_172 — Execute shows the missing function module in the status bar", async ({page, host}) => {
  await openExample(page, host, 172);
  const failed = page.waitForResponse((response) => new URL(response.url()).pathname === "/dispatch");
  await page.getByRole("button", {name: "Execute"}).click();
  expect((await failed).status()).toBe(500);

  await expect(page.locator("#wb-app-panel")).toBeVisible();
  await expect(statusMessage(page)).toHaveText(EXPLANATION);

  // The server keeps serving.
  await openExample(page, host, 172);
  await expectPageKind(page, "SELECTION");
});
