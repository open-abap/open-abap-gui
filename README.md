# open-abap-gui
GUI controls

## HTML host

The scaffold host can return a complete HTML5 document for report lists,
selection screens, messages, terminal results, and dynpro snapshots. The
page/request contract is transport-neutral; `zcl_gg_host_runtime` owns the
session and page history, while `host/html-http.mjs` is a small optional Node
HTTP adapter for GET/start and POST/dispatch requests.

The existing structured and text result fields remain available during the
migration. HTML output escapes dynamic text and attributes, keeps list `HIDE`
values server-side, and rejects unsafe picture URLs. See
[scaffold/PLAN3.md](scaffold/PLAN3.md) for the implementation ledger and
remaining GUI-control coverage.
The source-control registry and its intentional fallbacks are tracked in
[scaffold/GUI_HTML_CAPABILITIES.md](scaffold/GUI_HTML_CAPABILITIES.md).
SALV `display()` publishes its generated semantic table into the same registry;
registry extensions must provide already-safe generated HTML and must not pass
user text as markup.

The transport adapter and the sample launcher need only Node's built-in HTTP
module. Embed it by connecting the callbacks to the host runtime, or import
`host/html-launcher.mjs` for the same wiring:

```js
import {createHtmlHostServer} from "./host/html-http.mjs";

const server = createHtmlHostServer({
  start: ({url}) => runtime.start({url}),
  dispatch: (request) => runtime.dispatch(request),
  close: (sessionId) => runtime.close(sessionId),
});
server.listen(8080);
```
