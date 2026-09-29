import express from "express";
import {createServer} from "node:http";
import path from "node:path";
import {pathToFileURL} from "node:url";
import {createWorkbenchPreviewHandlers} from "../converter/src/workbench-http.mjs";

// A crash prints its whole stack; ABAP call chains exceed V8's default of 10.
Error.stackTraceLimit = Infinity;

const outputRoot = path.resolve(process.env.OPEN_ABAP_GUI_OUTPUT ?? "output");
await import(pathToFileURL(path.join(outputRoot, "init.mjs")).href);

function applyFixedSystemFields() {
  const system = globalThis.abap?.builtin?.sy?.get?.();
  if (!system) return;
  const fields = {
    datum: process.env.OPEN_ABAP_GUI_FIXED_DATE,
    datlo: process.env.OPEN_ABAP_GUI_FIXED_DATE,
    uzeit: process.env.OPEN_ABAP_GUI_FIXED_TIME,
    timlo: process.env.OPEN_ABAP_GUI_FIXED_TIME,
    uname: process.env.OPEN_ABAP_GUI_FIXED_USER,
    host: process.env.OPEN_ABAP_GUI_FIXED_HOST,
    sysid: process.env.OPEN_ABAP_GUI_FIXED_SYSID,
    mandt: process.env.OPEN_ABAP_GUI_FIXED_MANDT,
    langu: process.env.OPEN_ABAP_GUI_FIXED_LANG,
    zonlo: process.env.OPEN_ABAP_GUI_FIXED_TIMEZONE,
  };
  for (const [name, value] of Object.entries(fields)) {
    if (value !== undefined && system[name]?.set) system[name].set(value);
  }
  if (process.env.OPEN_ABAP_GUI_FIXED_TIMEZONE === "UTC" && system.tzone?.set) system.tzone.set(0);
}

applyFixedSystemFields();
const {cl_express_icf_shim} = await import(
  pathToFileURL(path.join(outputRoot, "cl_express_icf_shim.clas.mjs")).href);
const converterWorkbench = createWorkbenchPreviewHandlers();

const MAX_BODY_BYTES = 1024 * 1024;

// An exception that leaves a request handler is an application crash, not a
// response. Express would answer it and keep serving, so it is rethrown
// outside Express as an uncaught exception: Node prints the original stack
// and the process exits with a nonzero code, whether or not headers were sent.
function crash(error) {
  process.nextTick(() => {
    throw error;
  });
}

// This module is the transport adapter and executable server entry point.

export function createAbapHtmlHostServer() {
  const app = express();
  app.disable("x-powered-by");
  app.set("etag", false);
  app.use(express.raw({type: "*/*", limit: MAX_BODY_BYTES}));

  app.get("/converter/preview", async (request, response) => {
    try {
      await converterWorkbench.get(request, response);
    } catch (error) {
      crash(error);
    }
  });
  app.post("/converter/preview", async (request, response) => {
    try {
      await converterWorkbench.post(request, response);
    } catch (error) {
      crash(error);
    }
  });
  app.post("/converter/preview/save", async (request, response) => {
    try {
      await converterWorkbench.save(request, response);
    } catch (error) {
      crash(error);
    }
  });
  app.get("/converter/preview/download", async (request, response) => {
    try {
      await converterWorkbench.download(request, response);
    } catch (error) {
      crash(error);
    }
  });

  // The read-only converter preview is an explicit workbench adapter. All
  // other requests are handed to the fixed ABAP IF_HTTP_EXTENSION handler,
  // which owns the application behavior for the deployed GUI.
  app.all("*", async (request, response) => {
    try {
      await cl_express_icf_shim.run({
        req: request,
        res: response,
        class: "ZCL_GG_HTTP_HANDLER",
      });
    } catch (error) {
      crash(error);
    }
  });

  // Express reaches this only for its own errors. A client error from request
  // parsing, such as an oversized body, is answered; anything else crashes.
  app.use((error, request, response, next) => {
    const status = error?.status ?? error?.statusCode;
    if (error?.expose !== true || !(status >= 400 && status < 500) || response.headersSent) {
      crash(error);
      return;
    }
    response.status(status).type("application/json").send({
      valid: false,
      error: error.message,
    });
  });

  const server = createServer(app);
  let shutdownPromise;
  server.shutdown = async () => {
    shutdownPromise ??= Promise.resolve().then(() =>
      globalThis.abap.Classes.ZCL_GG_HTTP_HANDLER.shutdown());
    await shutdownPromise;
  };
  return server;
}

export function launchAbapHtmlHost({host = "127.0.0.1", port = 8080} = {}) {
  const server = createAbapHtmlHostServer();
  server.once("error", (error) => {
    if (error.code !== "EADDRINUSE") throw error;
    // Usually a server left running when Ctrl+C stopped npm but not its node child.
    const find = process.platform === "win32" ? `netstat -ano | findstr :${port}` : `lsof -i :${port}`;
    console.error(`Port ${port} on ${host} is already in use, probably by an earlier server that did not stop.`);
    console.error(`Find its PID with: ${find}`);
    process.exit(1);
  });
  server.listen(port, host, () => {
    const address = server.address();
    const actualPort = typeof address === "object" && address !== null ? address.port : port;
    const base = `http://${host}:${actualPort}`;
    console.log(`ABAP HTML server started at ${base}`);
  });
  return server;
}

const SHUTDOWN_TIMEOUT_MS = 3000;

// A SIGINT listener replaces Node's default exit, so every path here must end
// the process: normally by closing all handles, otherwise by the timeout.
function exitOnSignals(server) {
  let stopping = false;
  const stop = async (signal) => {
    if (stopping) {
      console.error(`${signal} received again, exiting`);
      process.exit(1);
    }
    stopping = true;
    console.log(`${signal} received, stopping server`);
    setTimeout(() => {
      console.error(`Server did not stop within ${SHUTDOWN_TIMEOUT_MS} ms; still open: ${process.getActiveResourcesInfo().join(", ") || "nothing"}`);
      process.exit(1);
    }, SHUTDOWN_TIMEOUT_MS).unref();
    const closed = new Promise((resolve) => server.close(resolve));
    // Browsers keep idle keep-alive sockets open, which would hold close() back.
    server.closeAllConnections();
    const [, teardown] = await Promise.allSettled([closed, server.shutdown()]);
    if (teardown.status === "rejected") console.error("ABAP shutdown failed:", teardown.reason);
  };
  process.on("SIGINT", stop);
  process.on("SIGTERM", stop);
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  const port = Number(process.env.OPEN_ABAP_GUI_PORT ?? 8080);
  exitOnSignals(launchAbapHtmlHost({port}));
}
