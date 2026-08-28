import {pathToFileURL} from "node:url";
import {createHtmlHostServer} from "./html-http.mjs";

const integrationEntries = [
  "ZCL_GG_DB_HELPER",
  "ZCL_GG_INTEGRATION_DYNPRO",
  "ZCL_GG_INTEGRATION_FAILURE",
  "ZCL_GG_INTEGRATION_FLIGHTS",
  "ZCL_GG_INTEGRATION_HTML_REPORT",
  "ZCL_GG_INTEGRATION_INTERACTIVE",
  "ZCL_GG_INTEGRATION_NAVIGATION",
  "ZCL_GG_INTEGRATION_SELECTION",
  "ZCL_GG_INTEGRATION_VARIANTS",
];

export function createAbapHtmlHostServer() {
  return createHtmlHostServer({
    shutdown: () => globalThis.abap.Classes.ZCL_GG_HTTP_HANDLER.shutdown(),
  });
}

export function launchAbapHtmlHost({host = "127.0.0.1", port = 8080} = {}) {
  const server = createAbapHtmlHostServer();
  server.listen(port, host, () => {
    const address = server.address();
    const actualPort = typeof address === "object" && address !== null ? address.port : port;
    const base = `http://${host}:${actualPort}`;
    console.log(`ABAP HTML server started at ${base}`);
    console.log(`  Index: ${base}/`);
    for (const className of integrationEntries) {
      console.log(`  ${className}: ${base}/${className}`);
    }
    console.log(`  Examples: ${base}/ZCL_GG_EX_01 through ${base}/ZCL_GG_EX_58`);
  });
  return server;
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  launchAbapHtmlHost();
}
