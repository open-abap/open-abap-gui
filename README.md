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
[scaffold/PLAN5.md](scaffold/PLAN5.md) for the transaction-code
implementation ledger and [scaffold/PLAN3.md](scaffold/PLAN3.md) for the
remaining GUI-control coverage.
The source-control registry and its intentional fallbacks are tracked in
[scaffold/GUI_HTML_CAPABILITIES.md](scaffold/GUI_HTML_CAPABILITIES.md).
SALV `display()` publishes its generated semantic table into the same registry;
registry extensions must provide already-safe generated HTML and must not pass
user text as markup.

Start the real ABAP-backed HTML server with one command:

```sh
npm start
```

This transpiles the ABAP scaffold and starts `test/start-server.mjs` on
`http://127.0.0.1:8080`. The fixed `/ZCL_GG_INTEGRATION_HTML_REPORT` and
`/ZCL_GG_INTEGRATION_DYNPRO` routes construct allow-listed integration
fixtures. The workbench uses transaction codes as the public application
identity. The index lists all 150 examples with their descriptions and
launches them through `/transaction?tcode=ZGG_EX_01`-style links. The command
field accepts `/nZGG_EX_01` for a report and `/nZGG_EX_58` for the dynpro
example; `/n` is case-insensitive and surrounding whitespace is allowed.
Unknown or malformed commands are reported in the accessible workbench shell
and never replace the current session.

The fixed `/ZCL_GG_INTEGRATION_HTML_REPORT`, `/ZCL_GG_INTEGRATION_DYNPRO`,
and `/ZCL_GG_EX_01` through `/ZCL_GG_EX_150` routes remain available as
compatibility/debug routes. Example class routes are authorized by the
transaction registry, the two integration fixtures are explicitly allow-listed,
and every other class-like path returns `404` without constructing a class.
They are not the public transaction identity.
`ZCL_GG_DB_HELPER` remains a separate database-fixture utility and does not
start an executable page.

To add a workbench application, implement `zif_gg_transaction_v1` alongside
exactly one of `zif_gg_report_v1` or `zif_gg_dynpro_v1`. Return a unique tcode
and user-facing description from `get_transaction`; the registry validates and
discovers the class automatically. Runtime application buttons belong to the
status supplied by the executable, not to the workbench shell:

```abap
io_session->get_list( )->set_status( VALUE #(
  active_ucomm = VALUE #( ( 'REFR' ) )
  icon_bar = VALUE #( ( ucomm = 'REFR' label = 'Refresh' icon = 'refresh' ) ) ) ).
```

The matching `AT USER-COMMAND` callback receives `REFR`; an initial `icon_bar`
renders no application buttons.
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
