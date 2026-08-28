import {pathToFileURL} from "node:url";
import {createHtmlHostServer} from "./html-http.mjs";

export function createAbapHtmlHostServer() {
  return createHtmlHostServer();
}

export function launchAbapHtmlHost({host = "127.0.0.1", port = 8080} = {}) {
  const server = createAbapHtmlHostServer();
  server.listen(port, host, () => {
    const address = server.address();
    const actualPort = typeof address === "object" && address !== null ? address.port : port;
    const base = `http://${host}:${actualPort}`;
    console.log(`ABAP HTML server started at ${base}`);
    console.log(`  Index: ${base}/`);
  });
  return server;
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  launchAbapHtmlHost();
}
