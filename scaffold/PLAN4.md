# Real end-to-end HTML host test plan

This plan closes the gap between the Node HTTP adapter, the transpiled ABAP
runtime, and browser verification. The target is a test in which Playwright
interacts with HTML produced by real ABAP code and every request returns through
the real `zcl_gg_host_runtime` session.

Every checkbox is one reviewable change with an observable result. Do not check
a box until its focused test passes. Keep behavior assertions in ABAP Unit
unless they require an HTTP or browser boundary.

## Non-negotiable constraints

- [ ] Define end to end as Playwright or `fetch` -> Node HTTP adapter -> ABAP
  runtime bridge -> transpiled `zcl_gg_host_runtime` -> ABAP renderer -> HTTP
  response.
- [ ] Do not define HTML strings, page builders, session maps, or transition
  state machines in JavaScript tests.
- [ ] Do not inject mocked or synthetic `start`, `dispatch`, or `close`
  callbacks. Callbacks supplied to `createHtmlHostServer` must delegate directly
  to the real ABAP runtime bridge.
- [ ] Do not duplicate ABAP business, selection-screen, list-processing,
  dynpro, navigation, validation, or session assertions in JavaScript.
- [ ] Keep the JavaScript bridge mechanical: construct ABAP inputs, invoke
  generated methods, and unwrap the public response fields needed by HTTP.
- [ ] Use stable semantic locators in Playwright: roles, labels, names, and
  public `data-*` page metadata. Do not select generated layout internals.
- [ ] Run every test on an ephemeral port and close browsers, servers, ABAP
  sessions, and database connections in `finally` blocks.
- [ ] A browser test must fail if the transpiled ABAP runtime or fixture cannot
  be loaded. It must never fall back to synthetic output.

## Current state and gaps

- `zcl_gg_host_runtime` already owns real session creation, page history,
  request validation, stale-page rejection, dispatch, and close behavior.
- `zif_gg_host_html_v1` already defines the typed request and response records
  shared by the report, dynpro, renderer, and transport boundaries.
- ABAP Unit covers report semantics, selection processing, list interaction,
  dynpro flow, navigation, failures, variants, and runtime round trips.
- `integration/html-snapshots.mjs` invokes transpiled ABAP directly, but bypasses
  HTTP and a browser.
- `integration/html-http.mjs` and `integration/html-smoke.mjs` use fake runtime
  callbacks and therefore test only the Node adapter.
- `integration/html-browser.mjs` uses JavaScript-generated pages and a
  JavaScript session state machine; it does not execute ABAP.
- `host/html-launcher.mjs` accepts a runtime facade, but no concrete facade for
  `abap.Classes.ZCL_GG_HOST_RUNTIME` exists.
- The browser script depends on a locally discovered Chrome executable and is
  not part of the current CI workflow.

## Target architecture

```mermaid
flowchart LR
  PW[Playwright] -->|HTTP forms and navigation| HTTP[host/html-http.mjs]
  HTTP --> BRIDGE[ABAP runtime bridge]
  BRIDGE --> RT[zcl_gg_host_runtime]
  RT --> REPORT[ABAP report or dynpro fixture]
  REPORT --> RENDERER[ABAP HTML renderer]
  RENDERER --> RT
  RT --> BRIDGE
  BRIDGE --> HTTP
  HTTP --> PW
```

The HTTP adapter remains transport-only. The bridge is the only JavaScript
module allowed to know both generated ABAP runtime objects and plain HTTP-facing
objects. Test fixtures, expected state transitions, and detailed behavior stay
in ABAP.

## Test ownership

### ABAP Unit

- Report and dynpro fixture behavior.
- Selection validation, defaults, help, and value help.
- List lines, hidden values, action tokens, user commands, PF keys, and back.
- Dynpro PBO, PAI, field transport, cursor context, and screen transitions.
- Session creation, isolation, stale requests, terminal sessions, and close.
- Renderer semantics, escaping, accessibility attributes, and page contracts.
- Error and recovery behavior.

### Node integration

- Loading transpiled ABAP and constructing a configured report or dynpro.
- Lossless conversion between HTTP payloads and `ty_request`.
- Lossless conversion of public `ty_response` fields to plain JavaScript.
- HTTP method, status, header, body-size, JSON, and form-encoding behavior.
- Proof that HTTP requests reach the real ABAP runtime.

### Playwright

- Browser form serialization and submit-button behavior.
- Accessible discovery and activation of controls.
- Focus, visibility, navigation, and rendered message announcements.
- A small number of representative real workflows across page kinds.
- Two independent browser contexts proving real session isolation.

## 1. Establish real ABAP fixtures

- [ ] Choose or add one deterministic report fixture under
  `scaffold/integration/` that starts on a selection page, supports help and
  value help, validates input, and renders a selectable list.
- [ ] Ensure a selected list line proves that hidden ABAP values remain on the
  server and are recovered by the opaque action token.
- [ ] Choose or add one deterministic dynpro fixture that exercises initial
  PBO, editable input, PAI, help/value help, next-screen navigation, back, and a
  terminal state.
- [ ] Reuse `zcl_gg_integration_db` for deterministic data setup and teardown;
  do not seed fixture data in JavaScript.
- [ ] Add ABAP Unit tests for every fixture transition before exposing it to
  HTTP.
- [ ] Add ABAP Unit runtime tests that perform the exact request sequence later
  used by Playwright and assert structured responses rather than parsed HTML.
- [ ] Add ABAP Unit tests for concurrent session isolation, explicit close, and
  deterministic reset.
- [ ] Keep browser-only expectations out of these fixture tests.

## 2. Add the transpiled ABAP runtime bridge

- [ ] Add a host module that imports `output/init.mjs` and exposes a plain
  `start`, `dispatch`, `close`, and `clear` runtime facade backed directly by
  `abap.Classes.ZCL_GG_HOST_RUNTIME`.
- [ ] Configure the facade with explicit report and dynpro factories. Do not
  accept arbitrary class names from an HTTP request.
- [ ] Instantiate only allow-listed ABAP entry points and verify that they
  implement the required report or dynpro interface.
- [ ] Initialize and reset integration data through transpiled ABAP fixture
  methods, not JavaScript SQL or duplicated rows.
- [ ] Convert a plain transport request into the generated
  `zif_gg_host_html_v1=>ty_request` shape without reinterpreting ABAP actions.
- [ ] Call `ZCL_GG_HOST_RUNTIME.dispatch` with the typed request and preserve
  empty strings, zero values, tables, ranges, and dynpro row numbers.
- [ ] Unwrap only the public response contract: `valid`, `error`, `session_id`,
  `page_id`, `page_kind`, `html`, and any diagnostics required by the adapter.
- [ ] Normalize `abap_bool` explicitly at the bridge boundary; do not rely on
  JavaScript truthiness for `X` and space.
- [ ] Forward close and clear operations to ABAP so no JavaScript session store
  is introduced.
- [ ] Surface generated-runtime exceptions as failed requests with useful test
  diagnostics; never replace them with a successful fallback page.
- [ ] Add one narrow Node contract test that calls the real bridge directly and
  proves start -> dispatch -> close against transpiled ABAP.

## 3. Wire a real HTTP server

- [ ] Update `host/html-launcher.mjs` to preserve start context such as the URL
  while delegating directly to the configured ABAP bridge.
- [ ] Add an executable server entry point that composes
  `createHtmlHostServer` with the real bridge and no test callbacks.
- [ ] Keep entry-point selection explicit and allow-listed, for example fixed
  report and dynpro routes used by both local development and tests.
- [ ] Start the server on port `0` in tests and return the selected address to
  the caller without parsing console output.
- [ ] Make server shutdown close active ABAP sessions and release the database
  connection.
- [ ] Preserve HTTP concerns in `host/html-http.mjs`: request parsing, body
  limits, content types, status mapping, and response headers.
- [ ] Ensure `GET` starts a real ABAP session, `POST /dispatch` invokes real
  ABAP dispatch, and `DELETE /session/:id` invokes real ABAP close.
- [ ] Add a real HTTP integration test for initial HTML, JSON dispatch,
  form-urlencoded dispatch, stale-page `409`, invalid JSON `400`, unknown route
  `405`, body limit, and session deletion.
- [ ] Assert an ABAP-specific fixture value in each successful HTTP response so
  the test cannot pass against a generic adapter stub.

## 4. Replace synthetic integration tests

- [ ] Rewrite `integration/html-http.mjs` to use the executable real ABAP host;
  remove local `start` and `dispatch` functions.
- [ ] Rewrite `integration/html-smoke.mjs` to start two real ABAP sessions and
  prove their page ids, values, histories, and close behavior remain isolated.
- [ ] Delete JavaScript `Map` session stores from integration tests.
- [ ] Delete JavaScript page, form, selection, list, dynpro, and HTML escaping
  helpers from browser tests.
- [ ] Remove any test callback that returns `{valid, html}` without invoking
  `ZCL_GG_HOST_RUNTIME`.
- [ ] Keep transport-only malformed-input cases in Node because ABAP never
  receives requests rejected by the HTTP parser.
- [ ] Move action and state assertions into ABAP Unit when they can be tested
  through `ty_request` and `ty_response` without HTTP.
- [ ] Replace `integration/html-snapshots.mjs` digest checks with focused ABAP
  Unit renderer contracts where equivalent coverage exists, then delete the
  script and npm hook if no unique cross-runtime behavior remains.

## 5. Playwright against real ABAP

- [ ] Rewrite `integration/html-browser.mjs` to launch the real ABAP-backed
  server in-process and navigate to its ephemeral URL.
- [ ] Verify the initial document and page metadata were emitted by the selected
  ABAP fixture.
- [ ] Fill a real selection field, submit the form, and assert the resulting
  ABAP list contents.
- [ ] Trigger real field help and value help and assert their accessible status
  output.
- [ ] Submit invalid input and assert the ABAP validation message, alert role,
  field association, retained value, and focus behavior.
- [ ] Activate a real selectable list row and assert the ABAP detail output.
- [ ] Verify hidden list values are absent from the DOM while the selected ABAP
  detail proves the server recovered them.
- [ ] Exercise a real user command or PF action and assert its ABAP-produced
  result.
- [ ] Open a real dynpro session, edit a field, submit PAI, and assert the next
  ABAP screen and value.
- [ ] Exercise real dynpro help/value help, back, and terminal behavior.
- [ ] Use two isolated browser contexts to prove separate real ABAP sessions do
  not leak values or page history.
- [ ] Capture session and page ids from rendered public metadata only; do not
  access ABAP globals from the Playwright test.
- [ ] Assert terminal pages expose no actionable form and closed sessions reject
  later dispatch.
- [ ] Ensure the Playwright test imports no generated ABAP classes directly;
  all interaction must cross HTTP.

## 6. Browser tooling and CI

- [ ] Use a reproducible Playwright browser installation instead of searching
  Windows-specific Chrome paths.
- [ ] Put Playwright and other test-only packages in `devDependencies`.
- [ ] Add a browser installation step to CI, including Linux system
  dependencies required by Chromium.
- [ ] Add a focused `test:html-e2e` npm script that transpiles ABAP before
  starting Playwright.
- [ ] Run the real HTTP integration test in the standard `npm test` path.
- [ ] Run the real Playwright test in CI on every pull request and push to main,
  either in `npm test` or a dedicated required job.
- [ ] Preserve complete server and browser diagnostics on failure while keeping
  successful CI output concise.
- [ ] Do not skip browser tests when Chromium is missing; fail setup with an
  actionable installation error.

## 7. Documentation and cleanup

- [ ] Document the real bridge and executable server in `README.md` with one
  supported startup command.
- [ ] Replace the generic runtime callback example with the concrete ABAP-backed
  composition.
- [ ] Document which checks belong to ABAP Unit, Node integration, and
  Playwright.
- [ ] Remove claims that synthetic browser or callback tests provide end-to-end
  coverage.
- [ ] Remove obsolete npm scripts and files after their real replacements pass.
- [ ] Update `scaffold/PLAN3.md` only to point to this plan for the end-to-end
  follow-up; do not rewrite its historical implementation record.

## Verification checklist

- [ ] Run `git diff --check`.
- [ ] Run `npm run lint`.
- [ ] Run `npm run unit`.
- [ ] Run the real bridge contract test.
- [ ] Run the real HTTP integration test.
- [ ] Run the real Playwright test with installed Chromium.
- [ ] Run `npm test` from a clean checkout.
- [ ] Run the CI workflow on Linux without machine-specific browser paths.
- [ ] Confirm no integration test defines HTML documents, fake runtime
  callbacks, or a JavaScript session state machine.
- [ ] Confirm browser requests invoke `ZCL_GG_HOST_RUNTIME.start`, `dispatch`,
  and `close` by observable ABAP fixture behavior, not implementation spies.

## Definition of done

- [ ] Playwright completes selection, validation, help/value help, list,
  line-selection, dynpro, back, and terminal interactions using HTML generated
  by transpiled ABAP.
- [ ] HTTP tests exercise the real ABAP runtime and retain only transport-owned
  assertions in JavaScript.
- [ ] ABAP Unit owns detailed fixture, runtime, renderer, and state-transition
  coverage.
- [ ] No integration or browser test can pass with ABAP output unavailable.
- [ ] No mocked callbacks, synthetic pages, duplicated session maps, or
  JavaScript transition models remain in the end-to-end suite.
- [ ] Two concurrent browser contexts prove real ABAP session isolation.
- [ ] Real browser coverage runs as a required Linux CI gate.