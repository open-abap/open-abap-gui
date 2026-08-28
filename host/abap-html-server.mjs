import {pathToFileURL} from "node:url";
import {createHtmlHostServer} from "./html-http.mjs";
import {createAbapHtmlRuntime} from "./abap-html-runtime.mjs";

const reportRuntime = createAbapHtmlRuntime({entryPoint: "report"});
const dynproRuntime = createAbapHtmlRuntime({entryPoint: "dynpro"});
const startRuntimes = new Map([
  ["/report", reportRuntime],
  ["/dynpro", dynproRuntime],
]);

function runtimeFor(url) {
  const runtime = startRuntimes.get(url.pathname);
  if (!runtime) throw new RangeError(`Unknown ABAP HTML route: ${url.pathname}`);
  return runtime;
}

export function createAbapHtmlHostServer() {
  const server = createHtmlHostServer({
    start: ({url}) => runtimeFor(url).start({url}),
    dispatch: (request) => reportRuntime.dispatch(request),
    close: (sessionId) => reportRuntime.close(sessionId),
    startPaths: [...startRuntimes.keys()],
  });
  server.shutdown = async () => reportRuntime.destroy();
  return server;
}

export function launchAbapHtmlHost({host = "127.0.0.1", port = 8080} = {}) {
  const server = createAbapHtmlHostServer();
  server.listen(port, host);
  return server;
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  launchAbapHtmlHost();
}