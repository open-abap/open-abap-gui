import express from "express";
import {createServer} from "node:http";
import path from "node:path";
import {pathToFileURL} from "node:url";
import {createWorkbenchPreviewHandlers} from "../converter/src/workbench-http.mjs";

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

// This module is the transport adapter and executable server entry point.

export function createAbapHtmlHostServer() {
  const app = express();
  app.disable("x-powered-by");
  app.set("etag", false);
  app.use(express.raw({type: "*/*", limit: MAX_BODY_BYTES}));

  app.get("/converter/preview", async (request, response, next) => {
    try {
      await converterWorkbench.get(request, response);
    } catch (error) {
      next(error);
    }
  });
  app.post("/converter/preview", async (request, response, next) => {
    try {
      await converterWorkbench.post(request, response);
    } catch (error) {
      next(error);
    }
  });
  app.post("/converter/preview/save", async (request, response, next) => {
    try {
      await converterWorkbench.save(request, response);
    } catch (error) {
      next(error);
    }
  });
  app.get("/converter/preview/download", async (request, response, next) => {
    try {
      await converterWorkbench.download(request, response);
    } catch (error) {
      next(error);
    }
  });

  // The read-only converter preview is an explicit workbench adapter. All
  // other requests are handed to the fixed ABAP IF_HTTP_EXTENSION handler,
  // which owns the application behavior for the deployed GUI.
  app.all("*", async (request, response, next) => {
    try {
      await cl_express_icf_shim.run({
        req: request,
        res: response,
        class: "ZCL_GG_HTTP_HANDLER",
      });
    } catch (error) {
      next(error);
    }
  });

  app.use((error, request, response, next) => {
    if (response.headersSent) {
      next(error);
      return;
    }
    response.status(400).type("application/json").send({
      valid: false,
      error: error instanceof Error ? error.message : String(error),
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
  server.listen(port, host, () => {
    const address = server.address();
    const actualPort = typeof address === "object" && address !== null ? address.port : port;
    const base = `http://${host}:${actualPort}`;
    console.log(`ABAP HTML server started at ${base}`);
  });
  return server;
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  const port = Number(process.env.OPEN_ABAP_GUI_PORT ?? 8080);
  launchAbapHtmlHost({port});
}
