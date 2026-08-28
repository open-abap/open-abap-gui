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

Start the real ABAP-backed HTML server with one command:

```sh
npm run start:html
```

This transpiles the ABAP scaffold and starts `host/abap-html-server.mjs` on
`http://127.0.0.1:8080`. The fixed `/report` and `/dynpro` routes construct
allow-listed ABAP fixtures; `host/abap-html-runtime.mjs` converts HTTP payloads
to typed `zcl_gg_host_runtime` requests and unwraps its public response.
The transport adapter remains responsible for HTTP parsing, limits, status
codes, and headers:

```js
import {createAbapHtmlHostServer} from "./host/abap-html-server.mjs";

const server = createAbapHtmlHostServer();
server.listen(8080);
```

Checks have separate ownership. ABAP Unit covers fixture behavior, renderer
contracts, and session semantics. Node integration covers the bridge and HTTP
transport contract. Playwright covers representative browser workflows and
real session isolation; install its managed browser with
`npm run install:html-browser` before running `npm run test:html-e2e` locally.
