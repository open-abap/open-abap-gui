import {createHtmlHostServer} from "./html-http.mjs";

// Small embedding example: the caller supplies the ABAP-backed runtime
// facade, so this launcher has no lifecycle or persistence policy of its own.
export function launchHtmlHost(runtime, {host = "127.0.0.1", port = 8080} = {}) {
  if (!runtime || typeof runtime.start !== "function" || typeof runtime.dispatch !== "function") {
    throw new TypeError("a host runtime with start and dispatch is required");
  }
  const server = createHtmlHostServer({
    start: ({url} = {}) => runtime.start({url}),
    dispatch: (request) => runtime.dispatch(request),
    close: (sessionId) => runtime.close?.(sessionId),
  });
  server.listen(port, host);
  return server;
}
