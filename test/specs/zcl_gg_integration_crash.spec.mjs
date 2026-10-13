import path from "node:path";
import {pathToFileURL} from "node:url";
import {test, expect, startHost, stopHost, expectPageKind, expectWorkbench} from "../fixtures.mjs";

// ZGG_INT_CAST_FAILURE fails its INITIALIZATION with a real cast error that
// no program handles. The HTTP handler answers the request with the
// exception's details, and the server keeps serving.
const CAST_FAILURE = "/program?name=ZGG_INT_CAST_FAILURE";
const DETAILS = "Unhandled exception CX_SY_MOVE_CAST_ERROR\nCasting failed, types not compatible";

// Sends the response headers before the ABAP handler runs the failing
// program, so the shim fails in JavaScript when it sends the handler's answer.
// start-server.mjs calls the shim through the registered class, so patching
// its run reaches the server.
function headersFirstServer() {
  const serverUrl = pathToFileURL(path.resolve("test/start-server.mjs")).href;
  return `
const {launchAbapHtmlHost} = await import(${JSON.stringify(serverUrl)});
const shim = globalThis.abap.Classes.CL_EXPRESS_ICF_SHIM;
const run = shim.run;
shim.run = async (input) => {
  if (input.req.query.name === "ZGG_INT_CAST_FAILURE") {
    input.res.writeHead(200, {"content-type": "text/html; charset=utf-8"});
    input.res.flushHeaders();
  }
  return run.call(shim, input);
};
launchAbapHtmlHost({port: 0});
`;
}

async function expectServing(baseUrl) {
  const program = await fetch(`${baseUrl}/program?name=ZGG_INT_PROGRAM`);
  expect(program.status).toBe(200);
  expect(await program.text()).toContain("started without a transaction");
}

test("an unhandled ABAP exception shows its details in the shell, F3 returns to the menu", async ({page, host}) => {
  const response = await page.goto(host.baseUrl + CAST_FAILURE);
  expect(response.status()).toBe(500);
  await expectPageKind(page, "ERROR");
  await expect(page.locator("main pre")).toHaveText(DETAILS);

  await page.keyboard.press("F3");
  await expectWorkbench(page);

  await expectServing(host.baseUrl);
});

test("an oversized request body is answered with 413", async ({host}) => {
  const response = await fetch(`${host.baseUrl}/dispatch`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: "x".repeat(1024 * 1024 + 1),
  });
  expect(response.status).toBe(413);
  expect(await response.json()).toEqual({valid: false, error: "PayloadTooLargeError: request entity too large"});

  await expectServing(host.baseUrl);
});

test("a failure after the response started closes the connection", async () => {
  const {child, baseUrl} = await startHost(["--input-type=module", "--eval", headersFirstServer()]);
  try {
    const response = await fetch(baseUrl + CAST_FAILURE);
    expect(response.status).toBe(200);
    await expect(response.text()).rejects.toThrow();

    await expectServing(baseUrl);
    expect(child.exitCode).toBeNull();
  } finally {
    await stopHost(child);
  }
});
