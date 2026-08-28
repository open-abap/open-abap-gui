# open-abap-gui
GUI controls

## HTML host

The scaffold host can return a complete HTML5 document for report lists,
selection screens, messages, terminal results, and dynpro snapshots. The
page/request contract is transport-neutral; `zcl_gg_host_runtime` owns the
session and page history, while `ZCL_GG_HTTP_HANDLER` owns the HTTP routes,
payload conversion, and response status/content type in ABAP.

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

This transpiles the ABAP scaffold and starts `test/start-server.mjs` on
`http://127.0.0.1:8080`. The fixed `/ZCL_GG_INTEGRATION_HTML_REPORT` and
`/ZCL_GG_INTEGRATION_DYNPRO` routes construct allow-listed integration
fixtures. The `/ZCL_GG_EX_01` through
`/ZCL_GG_EX_58` routes expose all of the ABAP examples through their
transpiled class counterparts; examples 01-57 are reports and example 58 is
a dynpro.
The index also lists all `ZCL_GG_INTEGRATION_*` classes. The executable
integration classes are available through the same ABAP-backed HTTP host;
`ZCL_GG_DB_HELPER` is listed as the database-fixture utility it is and
does not start an executable page.
Node only provides Express, request-body buffering, and the ICF-compatible
request/response shim:

```js
import {createAbapHtmlHostServer} from "./test/start-server.mjs";

const server = createAbapHtmlHostServer();
server.listen(8080);
```

The ABAP HTTP handler follows the same boundary as
[express-icf-shim](https://github.com/open-abap/express-icf-shim): Express
forwards the request to `IF_HTTP_EXTENSION`, and ABAP writes the response.

Checks have separate ownership. ABAP Unit covers fixture behavior, renderer
contracts, and session semantics. Playwright covers the real HTTP bridge,
representative browser workflows, and session isolation; install its managed
browser with
`npm run install:html-browser` before running `npm run test:html-e2e` locally.
