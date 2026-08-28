import express from "express";
import {createServer} from "node:http";
import "../output/init.mjs";
import {cl_express_icf_shim} from "../output/cl_express_icf_shim.clas.mjs";

const MAX_BODY_BYTES = 1024 * 1024;

// Node owns only the socket and Express request-body buffering. The ABAP ICF
// handler owns paths, forms, JSON, sessions, status codes, and response data.
export function createHtmlHostServer({
  handlerClass = "ZCL_GG_HTTP_HANDLER",
  base = "",
  shutdown = async () => {},
} = {}) {
  const app = express();
  app.disable("x-powered-by");
  app.set("etag", false);
  app.use(express.raw({type: "*/*", limit: MAX_BODY_BYTES}));

  app.all("*", async (request, response, next) => {
    try {
      await cl_express_icf_shim.run({
        req: request,
        res: response,
        class: handlerClass,
        base,
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
    const status = error?.status === 413 ? 400 : 400;
    response.status(status).type("application/json").send({
      valid: false,
      error: error instanceof Error ? error.message : String(error),
    });
  });

  const server = createServer(app);
  let shutdownPromise;
  server.shutdown = async () => {
    shutdownPromise ??= Promise.resolve().then(() => shutdown());
    await shutdownPromise;
  };
  return server;
}
