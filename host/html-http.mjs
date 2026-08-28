import express from "express";
import {createServer} from "node:http";
import "../output/init.mjs";
import {cl_express_icf_shim} from "../output/cl_express_icf_shim.clas.mjs";

const MAX_BODY_BYTES = 1024 * 1024;

// Node owns only the transport. Every request is handed to the fixed ABAP
// IF_HTTP_EXTENSION handler, which owns the HTTP application behavior.
export function createHtmlHostServer() {
  const app = express();
  app.disable("x-powered-by");
  app.set("etag", false);
  app.use(express.raw({type: "*/*", limit: MAX_BODY_BYTES}));

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
