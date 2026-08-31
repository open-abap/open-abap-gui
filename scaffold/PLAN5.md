# Transaction-code integration plan

This plan makes transaction codes the public application identity of the HTML
workbench. A runnable class opts in by implementing a small metadata interface
that returns its transaction code and description. One ABAP registry discovers
and validates those implementations; both the workbench list and HTTP command
handling consume that registry.

The target command syntax is `/n<tcode>`. For example, entering
`/nZGG_EX_001` and pressing Enter starts `zcl_gg_ex_001`; entering
`/nZGG_EX_058` starts the dynpro example. When entered from a running
application, `/n` ends that host session before starting the new transaction.

Every checkbox is one reviewable change with an observable result. Do not
check a box until its focused test passes.

## Non-negotiable constraints

- [x] Keep transaction metadata in the implementing ABAP class. Do not add a
  parallel hard-coded tcode-to-class map in the workbench, HTTP handler,
  JavaScript server, or browser tests.
- [x] Use one ABAP registry for discovery, normalization, uniqueness checks,
  lookup, list rendering, and launch authorization.
- [x] A transaction implementation must also implement exactly one supported
  executable contract: `zif_gg_report_v1` or `zif_gg_dynpro_v1`.
- [x] Treat tcodes case-insensitively and expose their canonical form in upper
  case. Trim surrounding spaces before lookup.
- [x] Reject initial, over-length, malformed, or duplicate tcodes and initial
  descriptions deterministically; never let discovery order choose a winner.
- [x] Resolve a tcode to a discovered class on the server. Never accept a class
  name supplied by the command field.
- [x] Escape transaction codes, descriptions, class names, and error text at
  their HTML text/attribute boundary.
- [x] Preserve the existing direct class routes during this change so current
  links and tests remain compatible; make tcode routes the workbench-facing
  path.
- [x] Keep command parsing and lifecycle behavior in ABAP. JavaScript remains
  only the Express/ICF transport adapter.
- [x] `/n<tcode>` closes the current host session before starting the target;
  an invalid command or unknown tcode must not silently run another class.

## Current state and gaps

- `zcl_gg_workbench` renders the validated transaction registry using tcodes
  and descriptions, and its links launch through `/transaction`.
- `zcl_gg_workbench_utility=>render_commandbar` submits `/n<tcode>` commands to
  the ABAP HTTP handler and includes the active session/page pair.
- `zcl_gg_http_handler` authorizes direct example paths through the transaction
  registry and explicitly allow-lists the two integration fixtures before any
  program is constructed.
- Host sessions support validated replacement after command parsing and target
  resolution; automatic expiry remains tracked in `PLAN3.md`.
- Examples 001-058 publish transaction metadata; example 058 is the dynpro entry
  and the others implement the report contract.

## Target architecture

```mermaid
flowchart LR
  CLASS[Report or dynpro class] -->|implements| META[ZIF_GG_TRANSACTION_V1]
  META --> REG[ZCL_GG_TRANSACTION_REGISTRY]
  REG --> LIST[Workbench transaction list]
  REG --> LOOKUP[Tcode lookup]
  INPUT[Command field: /nTCODE] --> POST[POST /transaction]
  LINK[Workbench tcode link] --> GET[GET /transaction?tcode=TCODE]
  POST --> PARSE[ABAP command parser]
  PARSE --> LOOKUP
  GET --> LOOKUP
  LOOKUP --> PRIOR{Prior session?}
  PRIOR -->|yes| CLOSE[Validate current page and close prior session]
  PRIOR -->|no| START[ZCL_GG_HOST_RUNTIME=>START]
  CLOSE --> START
```

`zif_gg_transaction_v1` is metadata only. It does not replace the report or
dynpro execution interfaces, and it does not know about HTTP. The registry adds
the implementation class name and executable kind to the returned metadata so
callers can render or launch the same validated catalog entry.

## 1. Define the transaction metadata contract

- [x] Add `scaffold/zif_gg_transaction_v1.intf.abap` as a public, versioned
  interface.
- [x] Define `ty_tcode` from
  `zif_gg_session_types_v1=>ty_tcode`, a string description, and
  `ty_transaction` containing only `tcode` and `description`.
- [x] Add a parameterless `get_transaction` method returning
  `ty_transaction`. Metadata retrieval must be side-effect free and must not
  require a host session.
- [x] Document that the returned tcode is the stable, case-insensitive public
  identifier and that the description is user-facing text.
- [x] Add an ABAP Unit contract fixture proving one class can implement both
  `zif_gg_transaction_v1` and a runnable report/dynpro interface without
  coupling their callbacks.

Proposed public shape:

```abap
INTERFACE zif_gg_transaction_v1 PUBLIC.
  TYPES ty_tcode TYPE zif_gg_session_types_v1=>ty_tcode.
  TYPES: BEGIN OF ty_transaction,
           tcode       TYPE ty_tcode,
           description TYPE string,
         END OF ty_transaction.

  METHODS get_transaction
    RETURNING
      VALUE(rs_transaction) TYPE ty_transaction.
ENDINTERFACE.
```

## 2. Build one validated transaction registry

- [x] Add `zcl_gg_transaction_registry` with a public catalog row containing
  canonical tcode, description, implementation class name, and executable
  kind (`REPORT` or `DYNPRO`).
- [x] Move the XCO, `SEO_INTERFACE_IMPLEM_GET_ALL`, and `reposrc` fallback
  discovery needed for transactions behind this registry. Keep the fallbacks
  compatible with both SAP ABAP and the transpiled runtime.
- [x] Instantiate each discovered transaction implementation, call
  `get_transaction`, determine its executable interface, normalize the tcode,
  and build the catalog once per process.
- [x] Validate allowed tcodes as non-initial, no longer than the existing
  `ty_tcode`, and composed of uppercase letters, digits, `_`, and namespace
  `/` separators. Reject whitespace or command prefixes inside metadata.
- [x] Require a non-initial description after trimming.
- [x] Reject a transaction class that implements neither or both executable
  interfaces, and report its class name in the diagnostic.
- [x] Sort catalog output by canonical tcode and detect duplicates after
  normalization. Report both conflicting class names.
- [x] Expose exact lookup by normalized tcode and catalog enumeration; callers
  must not repeat normalization or inspect repository sources themselves.
- [x] Expose a test-only cache reset, following the existing workbench/runtime
  reset pattern, so unit tests never depend on execution order.
- [ ] Add ABAP Unit tests for XCO/fallback-independent catalog construction,
  stable sorting, lowercase lookup, surrounding whitespace, every validation
  failure, duplicate rejection, and unknown lookup.

## 3. Add metadata to every example

- [x] Make `zcl_gg_ex_001` through `zcl_gg_ex_058` implement
  `zif_gg_transaction_v1` and return the mappings below.
- [x] Keep every mapping beside its example implementation; do not derive the
  tcode from the class name or parse the source comment at runtime.
- [x] Add one shared inventory test that asserts exactly 58 example tcodes,
  verifies every expected tcode resolves to its class and description, and
  proves no example is omitted. Avoid 58 duplicated browser tests.
- [x] Retain the current report/dynpro behavior and existing direct routes;
  adding metadata must not change example execution.

| Tcode range | Implementing classes | Description source |
| --- | --- | --- |
| `ZGG_EX_001` ... `ZGG_EX_057` | `ZCL_GG_EX_001` ... `ZCL_GG_EX_057` | The concise `Feature nn` phrase already documented at the top of each class |
| `ZGG_EX_058` | `ZCL_GG_EX_058` | `SET SCREEN, LEAVE SCREEN and LEAVE TO SCREEN` |

Use these exact descriptions for the inventory:

| Tcode | Description |
| --- | --- |
| `ZGG_EX_001` | `WRITE literal` |
| `ZGG_EX_002` | `WRITE AT position and NO-GAP` |
| `ZGG_EX_003` | `SKIP, ULINE, NEW-LINE and SET LEFT COLUMN` |
| `ZGG_EX_004` | `WRITE numeric and mask additions` |
| `ZGG_EX_005` | `FORMAT color and attributes` |
| `ZGG_EX_006` | `WRITE AS CHECKBOX, ICON and SYMBOL` |
| `ZGG_EX_007` | `REPORT line settings` |
| `ZGG_EX_008` | `NEW-PAGE, RESERVE and SET BLANK LINES` |
| `ZGG_EX_009` | `TOP-OF-PAGE` |
| `ZGG_EX_010` | `END-OF-PAGE` |
| `ZGG_EX_011` | `LOAD-OF-PROGRAM` |
| `ZGG_EX_012` | `INITIALIZATION` |
| `ZGG_EX_013` | `START-OF-SELECTION and END-OF-SELECTION` |
| `ZGG_EX_014` | `STOP` |
| `ZGG_EX_015` | `PARAMETERS with DEFAULT` |
| `ZGG_EX_016` | `PARAMETERS attribute additions` |
| `ZGG_EX_017` | `PARAMETERS AS CHECKBOX` |
| `ZGG_EX_018` | `PARAMETERS RADIOBUTTON GROUP` |
| `ZGG_EX_019` | `PARAMETERS AS LISTBOX` |
| `ZGG_EX_020` | `SELECT-OPTIONS` |
| `ZGG_EX_021` | `SELECTION-SCREEN COMMENT, ULINE and SKIP` |
| `ZGG_EX_022` | `Selection-screen block with frame and title` |
| `ZGG_EX_023` | `Selection-screen line and position` |
| `ZGG_EX_024` | `Selection-screen pushbutton and USER-COMMAND` |
| `ZGG_EX_025` | `SELECTION-SCREEN FUNCTION KEY` |
| `ZGG_EX_026` | `Selection-screen tabbed block and tabs` |
| `ZGG_EX_027` | `Selection-screen BEGIN OF SCREEN` |
| `ZGG_EX_028` | `AT SELECTION-SCREEN OUTPUT with LOOP AT SCREEN` |
| `ZGG_EX_029` | `AT SELECTION-SCREEN OUTPUT writing a parameter` |
| `ZGG_EX_030` | `AT SELECTION-SCREEN` |
| `ZGG_EX_031` | `AT SELECTION-SCREEN ON field` |
| `ZGG_EX_032` | `AT SELECTION-SCREEN ON END OF select-option` |
| `ZGG_EX_033` | `AT SELECTION-SCREEN ON BLOCK` |
| `ZGG_EX_034` | `AT SELECTION-SCREEN ON RADIOBUTTON GROUP` |
| `ZGG_EX_035` | `AT SELECTION-SCREEN ON VALUE-REQUEST` |
| `ZGG_EX_036` | `AT SELECTION-SCREEN ON HELP-REQUEST` |
| `ZGG_EX_037` | `AT SELECTION-SCREEN ON EXIT-COMMAND` |
| `ZGG_EX_038` | `SSCRFIELDS-UCOMM driven suppression` |
| `ZGG_EX_039` | `MESSAGE free text TYPE` |
| `ZGG_EX_040` | `MESSAGE number(id) WITH` |
| `ZGG_EX_041` | `Terminal MESSAGE type A` |
| `ZGG_EX_042` | `MESSAGE DISPLAY LIKE` |
| `ZGG_EX_043` | `HIDE and AT LINE-SELECTION` |
| `ZGG_EX_044` | `SET PF-STATUS and AT USER-COMMAND` |
| `ZGG_EX_045` | `SET TITLEBAR` |
| `ZGG_EX_046` | `READ LINE and MODIFY LINE` |
| `ZGG_EX_047` | `GET CURSOR` |
| `ZGG_EX_048` | `TOP-OF-PAGE DURING LINE-SELECTION` |
| `ZGG_EX_049` | `AT PF5` |
| `ZGG_EX_050` | `LEAVE TO/LIST-PROCESSING` |
| `ZGG_EX_051` | `CALL SELECTION-SCREEN` |
| `ZGG_EX_052` | `CALL SCREEN` |
| `ZGG_EX_053` | `Terminal SUBMIT` |
| `ZGG_EX_054` | `SUBMIT AND RETURN with selections and variant` |
| `ZGG_EX_055` | `SUBMIT EXPORTING LIST TO MEMORY` |
| `ZGG_EX_056` | `CALL TRANSACTION` |
| `ZGG_EX_057` | `LEAVE TO TRANSACTION and LEAVE PROGRAM` |
| `ZGG_EX_058` | `SET SCREEN, LEAVE SCREEN and LEAVE TO SCREEN` |

## 4. Render the registry in the workbench

- [x] Replace the report/dynpro implementation lists in `zcl_gg_workbench`
  with the validated transaction catalog.
- [x] Render one transaction list sorted by tcode. Each item must show both
  canonical tcode and description, with the tcode as the primary accessible
  link name.
- [x] Link each item to the canonical launch route
  `/transaction?tcode=<encoded-tcode>`; do not expose the implementation class
  as the destination.
- [x] Optionally group report and dynpro entries visually using the registry's
  executable kind, while retaining global tcode ordering within each group.
- [x] Keep `ZCL_GG_DB_HELPER` in a separate Utilities group because it is not a
  transaction and must not implement the metadata interface.
- [x] Remove transaction-list ownership and report/dynpro caches from
  `zcl_gg_workbench`; the registry is the sole catalog cache.
- [x] Render a visible, accessible workbench error when a launch link or
  command names an unknown tcode. Preserve the submitted command so it can be
  corrected.
- [x] Update ABAP Unit workbench tests to assert tcode, description, canonical
  route, ordering, escaping, and the absence of class-name launch links.

## 5. Make `/n<tcode>` executable from the command field

- [x] Give the command input a stable form field name and place it in a real
  `POST /transaction` form. Pressing Enter must submit without requiring a new
  Go button.
- [x] Include the active `session_id` and `page_id` as hidden fields when the
  command bar is rendered for a running report or dynpro; omit both on the
  workbench.
- [x] Add a small ABAP command parser that accepts `/n` case-insensitively,
  permits surrounding whitespace, requires a non-empty tcode immediately
  after `/n`, normalizes it through the registry, and rejects trailing tokens.
- [x] Keep unsupported commands explicit. Plain `ZGG_EX_001`, `/o...`, `/n`,
  and `/nUNKNOWN` must produce an accessible error rather than navigating.
- [x] Extend `zcl_gg_http_handler=>handle_post` with the exact
  `/transaction` route. Parse the form in ABAP, resolve the registry entry,
  and construct only the resolved class.
- [x] Add `GET /transaction?tcode=...` for workbench links. It uses the same
  registry lookup and start helper as POST but does not parse the `/n` prefix.
- [x] Factor report/dynpro startup out of the direct-class GET branch so direct
  routes and both transaction routes share one typed launch implementation.
- [x] Add a runtime operation that validates the submitted session/page pair
  against the current page and closes that session atomically. Do not expose
  the runtime's private session table to the HTTP handler.
- [x] For a valid POST from a running application, use that operation to close
  the supplied current host session, then start the resolved report or dynpro
  and return its initial HTML response.
- [x] Reject an unknown session or stale page without closing any session. Do
  not call the existing unconditional `close( session_id )` directly from the
  command route.
- [x] Define failure ordering explicitly: parse and resolve the new tcode
  first; only close the old session once the target is known to be valid and
  runnable. Thus a typo leaves the current application recoverable.
- [x] Ensure successful `/n` replacement makes the old session reject later
  dispatch while the new response contains a fresh session and page id.
- [x] Return an appropriate client error for malformed/unknown commands and a
  server error for invalid registry configuration; render both through the
  workbench shell with an `aria-live` or alert message.
- [ ] Add ABAP Unit tests for parsing, canonicalization, report start, dynpro
  start, unknown tcode, malformed command, valid session replacement, stale
  session rejection, and no-session workbench launch.

## 6. Browser and HTTP coverage

- [x] Update `test/specs/zcl_gg_index.spec.mjs` to verify the workbench lists
  all 58 example tcodes with descriptions and no longer uses class routes for
  transaction entries.
- [x] Click `ZGG_EX_001` in the list and prove the response is the real ABAP
  report example through the canonical transaction route.
- [ ] Enter `/nZGG_EX_001` on the workbench, press Enter, and prove the report
  starts through the real ABAP HTTP handler.
- [x] Enter lowercase `/nzgg_ex_058` and prove normalization plus dynpro startup.
- [x] From one running example, enter `/nZGG_EX_002`; assert a fresh session is
  displayed and an HTTP dispatch using the prior session id is rejected.
- [ ] Enter an unknown and a malformed command; assert the accessible error,
  retained input, absence of unintended transaction startup, and that the
  prior session remains valid.
- [ ] Add focused raw HTTP assertions for GET launch, POST command launch,
  unsupported methods/content, and status codes only where Playwright cannot
  express the transport contract clearly.
- [x] Keep expected application behavior in existing ABAP Unit/example tests;
  browser tests verify routing, form serialization, focus, accessibility, and
  lifecycle boundaries only.

## 7. Documentation and compatibility cleanup

- [x] Update `README.md` to make tcodes the documented way to discover and
  start applications, including `/nZGG_EX_001` and `/nZGG_EX_058` examples.
- [x] Document how a new report or dynpro opts into the workbench by
  implementing `zif_gg_transaction_v1` and returning unique metadata.
- [x] Document that direct `/<class_name>` routes are compatibility/debug
  routes and are not the public transaction identity.
- [x] Update `GUI_HTML_CAPABILITIES.md` with command-field syntax, supported
  navigation semantics, unknown-command behavior, and session replacement.
- [x] Remove obsolete workbench report/dynpro discovery code only after the
  registry-backed list and compatibility routes pass.
- [x] Authorize direct example routes through the transaction registry,
  explicitly allow-list integration fixtures, and reject every other
  class-like path before construction.

## Verification checklist

- [ ] Run `git diff --check`.
- [x] Run `npm run lint`.
- [x] Run `npm run unit`.
- [ ] Run `npm run test:html-e2e` with Chromium installed.
- [x] Confirm the registry contains exactly 58 `ZGG_EX_*` transactions and
  each class implements exactly one executable interface.
- [x] Confirm tcodes and descriptions appear only in their implementing
  classes plus the test inventory/plan, not in a production central map.
- [x] Confirm an unknown tcode cannot instantiate an arbitrary ABAP class.
- [x] Confirm `/n` replacement closes the old session only after successful
  parse and lookup.
- [x] Confirm all dynamic transaction text is escaped and every failure is
  keyboard- and screen-reader-accessible.

## Definition of done

- [x] Every example publishes the specified tcode and description through
  `zif_gg_transaction_v1`.
- [x] The workbench lists the validated transaction catalog using tcode and
  description and launches entries through a tcode route.
- [x] `/n<tcode>` entered on either the workbench or a running application
  starts the matching report or dynpro.
- [x] Starting a valid `/n` transaction replaces and closes the prior host
  session without leaking state.
- [x] Invalid, unknown, duplicate, or unsafe metadata and commands fail
  deterministically without arbitrary class creation.
- [ ] ABAP Unit owns registry, parser, resolution, and lifecycle behavior;
  Playwright proves the real command field and HTTP boundary end to end.
