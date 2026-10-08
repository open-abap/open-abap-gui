// An unexpected ABAP exception during a web request must terminate the whole
// server process with its original stack, not become a JSON error response.
// Each test starts the real server as a subprocess on transpiled output.
import {test} from "node:test";
import assert from "node:assert/strict";
import {spawn} from "node:child_process";
import {once} from "node:events";
import path from "node:path";
import {pathToFileURL} from "node:url";

const STARTUP_TIMEOUT_MS = 30_000;
const EXIT_TIMEOUT_MS = 15_000;
const CAST_FAILURE_PATH = "/program?name=ZGG_INT_CAST_FAILURE";

const serverUrl = pathToFileURL(path.resolve("test/start-server.mjs")).href;

// Sends the response headers before the ABAP handler runs, so the handler's
// exception arrives after headers are sent. start-server.mjs calls the shim
// through the registered class, so patching its run reaches the server.
const HEADERS_FIRST_SERVER = `
const {launchAbapHtmlHost} = await import(${JSON.stringify(serverUrl)});
const cl_express_icf_shim = globalThis.abap.Classes.CL_EXPRESS_ICF_SHIM;
const run = cl_express_icf_shim.run;
cl_express_icf_shim.run = async (input) => {
  input.res.writeHead(200, {"content-type": "text/html; charset=utf-8"});
  input.res.flushHeaders();
  return run.call(cl_express_icf_shim, input);
};
launchAbapHtmlHost({port: 0});
`;

function startServer(args) {
  const child = spawn(process.execPath, args, {
    env: {...process.env, OPEN_ABAP_GUI_PORT: "0"},
    stdio: ["ignore", "pipe", "pipe"],
  });
  const output = {stdout: "", stderr: ""};
  child.stdout.setEncoding("utf8");
  child.stderr.setEncoding("utf8");
  child.stdout.on("data", (chunk) => { output.stdout += chunk; });
  child.stderr.on("data", (chunk) => { output.stderr += chunk; });
  const exited = once(child, "exit").then(([code, signal]) => ({code, signal}));
  const started = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`Server did not start: ${output.stderr}`)), STARTUP_TIMEOUT_MS);
    child.stdout.on("data", () => {
      const match = output.stdout.match(/ABAP HTML server started at (http:\/\/127\.0\.0\.1:\d+)/);
      if (!match) return;
      clearTimeout(timeout);
      resolve(match[1]);
    });
    exited.then(({code}) => {
      clearTimeout(timeout);
      reject(new Error(`Server exited during startup (${code}): ${output.stderr}`));
    });
  });
  return {child, output, exited, started};
}

async function waitForExit(server) {
  let timer;
  const timeout = new Promise((resolve) => {
    timer = setTimeout(resolve, EXIT_TIMEOUT_MS, "timeout");
  });
  const result = await Promise.race([server.exited, timeout]);
  clearTimeout(timer);
  if (result === "timeout") {
    server.child.kill();
    assert.fail(`Server was still running ${EXIT_TIMEOUT_MS} ms after the failing request`);
  }
  return result;
}

function assertCrashedWithCastStack(exit, output) {
  assert.equal(exit.signal, null, output.stderr);
  assert.notEqual(exit.code, 0, output.stderr);
  // The stack starts where the runtime raises the cast error and passes the
  // failing ABAP method, the HTTP handler and the ICF shim on its way out.
  assert.match(output.stderr, /statements[\\/]cast\.js/, output.stderr);
  assert.match(output.stderr, /zcl_gg_integration_crash\.clas\.mjs/, output.stderr);
  assert.match(output.stderr, /initialization/, output.stderr);
  assert.match(output.stderr, /zcl_gg_http_handler\.clas\.mjs/, output.stderr);
  assert.match(output.stderr, /cl_express_icf_shim\.clas\.mjs/, output.stderr);
  assert.doesNotMatch(output.stderr, /Casting failed, types not compatible"\}/, output.stderr);
}

test("an ABAP cast failure terminates the server with its original stack", async () => {
  const server = startServer(["test/start-server.mjs"]);
  const baseUrl = await server.started;

  const request = fetch(baseUrl + CAST_FAILURE_PATH).then(
    (response) => response.text().then((body) => ({status: response.status, body})),
    (error) => ({error}));
  const exit = await waitForExit(server);
  const response = await request;

  assertCrashedWithCastStack(exit, server.output);
  assert.ok(response.error, `The request got a response instead of a crash: ${JSON.stringify(response)}`);
});

test("an ABAP cast failure after the response headers were sent terminates the server", async () => {
  const server = startServer(["--input-type=module", "--eval", HEADERS_FIRST_SERVER]);
  const baseUrl = await server.started;

  const response = await fetch(baseUrl + CAST_FAILURE_PATH);
  assert.equal(response.status, 200);
  const body = response.text().then(() => "completed", (error) => error);
  const exit = await waitForExit(server);

  assertCrashedWithCastStack(exit, server.output);
  assert.notEqual(await body, "completed");
});

test("request validation errors are answered and the server keeps running", async () => {
  const server = startServer(["test/start-server.mjs"]);
  const baseUrl = await server.started;

  try {
    const unknownProgram = await fetch(baseUrl + "/program?name=ZGG_INT_UNKNOWN");
    assert.match(await unknownProgram.text(), /Unknown program: ZGG_INT_UNKNOWN/);

    const staleSession = await fetch(baseUrl + "/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: "HOST-404", page_id: "HOST-404-1", action: "SUBMIT"}),
    });
    assert.equal(staleSession.status, 400);
    assert.deepEqual(await staleSession.json(), {valid: false, error: "Unknown host session"});

    const tooLarge = await fetch(baseUrl + "/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: "x".repeat(1024 * 1024 + 1),
    });
    assert.equal(tooLarge.status, 413);

    const program = await fetch(baseUrl + "/program?name=ZGG_INT_PROGRAM");
    assert.equal(program.status, 200);
    assert.match(await program.text(), /started without a transaction/);

    assert.equal(server.child.exitCode, null, server.output.stderr);
  } finally {
    server.child.kill();
    await server.exited;
  }
});
