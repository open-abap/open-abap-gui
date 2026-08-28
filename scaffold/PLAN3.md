# HTML host rendering plan

This plan turns the scaffold host into a page renderer. The target is that a
report or dynpro execution produces a complete, safe HTML document for the
currently visible processor state, while retaining the existing structured
result and text-line output during migration.

The plan is intentionally implementation-sized: every checkbox is one reviewable
change with one observable result. Do not check a box until its focused test and
the repository verification command pass.

The real end-to-end HTML host follow-up is tracked in
[scaffold/PLAN4.md](PLAN4.md).

When the transpiler does not support a statement or construct, record the gap
in `scaffold/ANORMALIES.md`. Include the feature/report, the exact
statement, the transpiler error, and the verification date. Keep the related
checklist item open until the report passes the runtime gate, unless the plan
explicitly documents a different host or scaffold blocker.

## Current state and discovered gaps

- The report and dynpro hosts now return complete HTML documents alongside their
  compatibility fields; the runtime keeps a page history per session.
- List output retains semantic fragments, formats, and hidden-field associations
  while preserving the original text-line API.
- Selection and dynpro builders retain operation-specific control metadata and
  the renderers produce keyboard-usable HTML forms.
- The source GUI layer now has a control snapshot registry for containers, text
  edits, pictures, toolbars, calendars, HTML viewers, ALV/tree models, SALV
  tables, and graphics fallbacks; report list pages embed the registry fragment
  when a report creates controls. Structured ALV reflection remains limited by
  the repository's dynamic-access rule; see `ANORMALIES.md`.
- `host/html-http.mjs` provides the transport-neutral contract over Node's
  built-in HTTP server; it does not embed ABAP lifecycle logic.
- The stateful runtime pauses resumable report continuations at an HTML
  selection or navigation page and resumes them on the next typed request;
  direct `zcl_gg_host=>run` callers retain eager single-run behavior.

## Scope and invariants

- [x] Define the first HTML contract as a complete document (`<!doctype
  html>`, `html`, `head`, `body`) returned by the host, not a partial fragment.
- [x] Define the visible page kinds: selection screen, classic list, dynpro,
  message/error, and terminal/navigation result.
- [x] Define whether a run returns only the current page or both the current page
  and an ordered page history; document the choice in the public result type.
- [x] Define stable, namespaced HTML `id` and `name` rules from ABAP program,
  screen, control, list level, and row identifiers.
- [x] Define the browser event envelope for submit, button, tab, list-line,
  function-code, value-help, field-help, and back actions.
- [x] Define which state is server-owned and which values may be sent back by the
  browser; do not expose raw `HIDE` values or continuation internals by default.
- [x] Define the compatibility policy for `lines`, `line_formats`, `elements`,
  `states`, and dynpro result fields while `html` is introduced.
- [x] Define the supported HTML baseline (HTML5, UTF-8, no client framework,
  keyboard-accessible controls) and the allowed inline/style asset strategy.
- [x] Define the security policy: escape text and attributes, reject unsafe URLs,
  prevent raw ABAP text from becoming markup, and avoid executable user data.
- [x] Add a short architecture section to `README.md` linking to this plan and
  explaining that HTML rendering is transport-neutral.

## 1. Page, request, and response model

- [x] Add a versioned page vocabulary interface for page kind, page id, session
  id, processor, title, status, and terminal state.
- [x] Add typed page-action records containing action kind, user command, target
  control, target row, and opaque state token.
- [x] Add a typed request record for session id, page id, action, input values,
  selected list line, cursor data, PF key, and help/value-request target.
- [x] Add a typed response record containing current page, HTML document, page
  kind, page id, messages, and the structured compatibility result.
- [x] Add a page collection type that preserves page order without requiring
  callers to parse HTML.
- [x] Add an explicit renderer context carrying program, processor, screen/list
  level, locale-independent formatting settings, and CSP nonce if needed.
- [x] Add a session lifecycle object with start, dispatch, render, and close
  operations; keep it separate from static variant storage.
- [x] Add a deterministic session id and page id generator suitable for ABAP Unit.
- [x] Add expiry/clear operations for host sessions so state cannot leak between
  repeated executions or tests.
- [x] Add focused tests for request validation, unknown session, stale page id,
  unknown action, and terminal response behavior.

## 2. Safe HTML primitives and document shell

- [x] Add one HTML escaping utility for text nodes and one for attribute values.
- [x] Add safe URL validation for browser, picture, and link-like controls; reject
  `javascript:`, unsafe schemes, and untrusted markup URLs.
- [x] Add attribute rendering that omits initial optional attributes and escapes
  every emitted value.
- [x] Add element helpers for opening/closing tags, void tags, text nodes, and
  deterministic attribute ordering.
- [x] Add a document-shell renderer with doctype, charset, viewport, title,
  base stylesheet, message region, and main content region.
- [x] Add page-level `data-page-id`, `data-session-id` handling without putting
  private continuation state in visible HTML.
- [x] Add a CSP-compatible style strategy and test that generated dynamic text
  cannot break out of an element or attribute.
- [x] Add golden tests for empty, Unicode, quotes, ampersands, angle brackets,
  newlines, and long values.

## 3. Capture a complete classic-list render model

- [x] Extend `zcl_gg_host_list` with a typed page/row model instead of deriving
  HTML from trimmed `mt_lines` after the fact.
- [x] Record each write fragment's source text, rendered text, start column,
  width, justification, current format, and hidden-field association.
- [x] Record checkbox, icon, and symbol fragments with semantic kind and display
  fallback separately from their text representation.
- [x] Record explicit line breaks, skipped lines, underlines, and page boundaries
  as model events.
- [x] Record list level, page number, line number, title, status, and navigation
  actions on the model.
- [x] Preserve `READ LINE` and `MODIFY LINE` behavior when a line is represented
  by fragments rather than only a string.
- [x] Preserve hidden values in host-owned state and give each selectable line an
  opaque action token.
- [x] Preserve existing `finish_output` and `get_line_formats` behavior for all
  current tests.
- [x] Add model tests for placement, gaps, fixed widths, justification, format
  changes, page breaks, hidden values, and line modification.

## 4. Render classic lists as HTML pages

- [x] Add a list-page renderer that emits the title, status, page sections, and
  list body through the document shell.
- [x] Render fixed-column output with a layout that preserves classic spacing and
  does not collapse repeated spaces on narrow screens.
- [x] Render each output fragment with escaped text and its format classes/data
  attributes rather than applying formatting only to the whole line.
- [x] Map classic colors, intensified, inverse, hotspot, input, and quickinfo to
  deterministic CSS classes and accessible text/title attributes.
- [x] Render checkboxes, icons, symbols, and unknown icon names with visible,
  accessible fallbacks.
- [x] Render `HIDE` lines as keyboard- and pointer-selectable actions while
  keeping hidden values out of the visible source and client payload where
  possible.
- [x] Render `SET PF-STATUS`, excluded commands, titles, and function-code
  actions as page controls with disabled/excluded states.
- [x] Render list-level navigation and back actions using the request envelope.
- [x] Render page breaks as separate semantic sections with page metadata.
- [x] Render informational, warning, error, abort, and exit messages in the
  correct accessible message region and severity style.
- [x] Add HTML assertions for the existing examples 01–14 and 43–50.
- [x] Add an interactive integration test that dispatches a rendered line action
  and receives the same detail-list semantics as the current text host.

## 5. Preserve and render selection-screen definitions

- [x] Expand `zcl_gg_host_screen=>ty_element` or add typed element tables so all
  builder inputs survive: data type, visible length, fixed values, flags,
  `for_field`, modification groups, and screen identity.
- [x] Preserve block nesting and associate each rendered element with its block,
  line, position, and source order.
- [x] Preserve tabbed-block/tab relationships and the selected/default tab.
- [x] Preserve named selection-screen metadata (`SCREEN nnn`, window,
  subscreen) instead of treating all screens as `1000`.
- [x] Add a screen snapshot containing definition, current values, current states,
  messages, and available actions.
- [x] Add tests proving that `AT SELECTION-SCREEN OUTPUT` mutations are reflected
  in the snapshot and that PAI mutations follow the documented lifecycle.

## 6. Render selection screens as HTML pages

- [x] Add a selection-page renderer for parameters with labels, values, lengths,
  types, defaults, required state, lower-case state, and no-display state.
- [x] Render checkboxes with checked state and associated user command.
- [x] Render radio-button groups with one semantic group and checked state.
- [x] Render listboxes with escaped fixed-value labels and selected keys.
- [x] Render select-options as low/high/range rows with sign and option inputs,
  including `NO-EXTENSION` and `NO-INTERVALS` restrictions.
- [x] Render comments, labels, underlines, skips, explicit positions, and line
  groups without losing source order.
- [x] Render blocks as `fieldset`/`legend` when framed and as accessible groups
  when not framed.
- [x] Render pushbuttons, function keys, tabs, and screen/window actions as
  page actions carrying their ABAP user commands.
- [x] Render field help and value-help affordances only when the corresponding
  state permits them.
- [x] Add accessible error association from messages to the affected field/row.
- [x] Add a form serializer/parser mapping HTML names back to typed host values
  and ranges without changing ABAP field names.
- [x] Add request-dispatch tests for submit, cancel/exit, pushbutton, tab,
  value-help, help, radio group, and range actions.
- [x] Add HTML assertions for examples 15–38 and the selection integration suite.

## 7. Capture and render dynpro definitions

- [x] Extend `zcl_gg_host_dynpro_builder` to retain every typed control in screen
  and source order instead of returning from the control methods.
- [x] Retain positions, dimensions, modification ids, data types, required flags,
  value-help flags, password flags, fixed values, and user commands.
- [x] Retain table-control columns, widths, input flags, required flags, and
  visible-row settings.
- [x] Retain tabstrip/tab, box, subscreen-area, custom-control, and nested screen
  relationships.
- [x] Extend `zcl_gg_host_dynpro_flow` to retain fields, modules, chains,
  table-loop context, subscreen calls, POV, and POH in execution order.
- [x] Add a typed dynpro snapshot containing screen definition, current values,
  current states, flow metadata, title, status, cursor, and messages.
- [x] Make session context report the active processor (`DYNPRO`, `LIST`, or
  `SELECTION`) and active screen/list level during each callback.
- [x] Add builder and flow tests proving that no supported definition operation is
  silently discarded.

## 8. Render dynpros as HTML pages

- [x] Add a dynpro-page renderer using screen dimensions and a responsive CSS
  coordinate system with a documented pixel/grid conversion.
- [x] Render input and output fields with typed values, labels, enabled/visible/
  required state, uppercase/password behavior, and value-help affordances.
- [x] Render pushbuttons, checkboxes, radio buttons, listboxes, boxes, and text
  controls with their user commands and accessible labels.
- [x] Render tabs and subscreens with stable targets and correct selected state.
- [x] Render table controls with headings, rows, scrolling metadata, and input
  cells while preserving table-control names and row indexes.
- [x] Render custom controls as explicit named placeholders with an extension
  point instead of silently dropping them.
- [x] Render title, status, cursor focus, and modal/window metadata.
- [x] Map form submissions to PAI module context, including field, row, cursor,
  user command, and table-loop information.
- [x] Drive PBO before each rendered screen and PAI only for a submitted action.
- [x] Drive POV/POH actions and return their values/help as HTML page state.
- [x] Implement repeated screen transitions, back, leave-screen, leave-to-screen,
  and terminal transitions in the session object.
- [x] Add HTML assertions for dynpro integration scenarios and example 58.
- [x] Add a browser-level round-trip test for input → PAI → returned screen.

## 9. Navigation, continuations, messages, and multi-page execution

- [x] Represent `CALL SELECTION-SCREEN`, `CALL SCREEN`, `SUBMIT ... AND RETURN`,
  and `CALL TRANSACTION` as page transitions with resumable state.
- [x] Represent terminal `SUBMIT`, `LEAVE PROGRAM`, and `LEAVE TO TRANSACTION`
  as terminal HTML responses with no false continuation action.
- [x] Render a navigation/history surface only when it corresponds to a valid
  host-owned continuation; do not infer navigation from arbitrary HTML.
- [x] Preserve list memory output as a structured page snapshot as well as the
  existing text table.
- [x] Preserve variant behavior across requests without sharing report execution
  state between sessions.
- [x] Render message `DISPLAY LIKE` separately from message control flow so an
  error remains an error even when displayed with another style.
- [x] Add tests for nested selection, nested dynpro, submit-and-return, list
  memory, transaction return, terminal navigation, and message retry.
- [x] Add stale-session, duplicate-submit, back-after-terminal, and invalid-token
  tests.

## 10. Connect existing GUI controls to the HTML host

This phase covers the separate `src/` compatibility classes. It must not make
the scaffold report renderer depend on concrete GUI classes; use a host control
registry/adapter boundary instead.

- [x] Inventory every concrete GUI class and mark each method as model, render,
  event, or intentional no-op in a maintained capability table.
- [x] Add a host control registry keyed by control id and parent/container id.
- [x] Make `cl_gui_object`/`cl_gui_control` retain identity, parent, geometry,
  enabled, visible, focus, and lifetime state needed by the registry.
- [x] Make container classes retain child order and containment.
- [x] Render custom containers, docking containers, dialog boxes, splitters, and
  easy splitters as HTML layout regions.
- [x] Render `cl_gui_textedit` as an accessible textarea with get/set/selection
  state and change actions.
- [x] Render `cl_gui_picture` as a safe image element with size and alignment.
- [x] Render `cl_gui_toolbar` as an accessible toolbar with enabled/disabled
  buttons and command actions.
- [x] Render `cl_gui_calendar` and selector controls with HTML form controls and
  ABAP-compatible values.
- [x] Render ALV grid data, columns, sorting/filtering/selection metadata, and
  toolbar actions as a semantic table page.
- [x] Render tree controls with nested lists, expansion state, node selection,
  drag/drop capability flags, and actions.
- [x] Render SALV-backed list/table/tree models through the same page renderer.
- [x] Render graphics/chart objects through a documented HTML/SVG or fallback
  representation without introducing unsafe raw SVG.
- [x] Implement `cl_gui_html_viewer` against the registry/page store so
  `load_data`, `show_data`, `show_url`, navigation, and refresh have observable
  host behavior.
- [x] Implement `cl_abap_browser=>show_html` as a host page/modal request and
  preserve title, container, dialog, and printing flags.
- [x] Define intentional behavior for frontend services, timers, drag/drop, and
  progress indicators when no browser equivalent exists.
- [x] Add control-level tests for lifecycle, geometry, visibility, events, and
  safe content handling.
- [x] Add one end-to-end fixture combining a report, container, ALV/tree/text
  control, and HTML viewer in one rendered page.

## 11. Transport adapter and browser verification

- [x] Decide whether the first transport is a Node `http` adapter, an embedding
  API, or both; record the decision and its session ownership rules.
- [x] Add a minimal transport adapter that maps GET/start and POST/dispatch to the
  typed host request/response contract without embedding ABAP lifecycle logic.
- [x] Add content-type, charset, cache, and error responses for the adapter.
- [x] Add a sample page launcher using only repository dependencies or document the
  explicit extra dependency if one is unavoidable.
- [x] Add browser tests for initial selection page, form submit, list selection,
  dynpro PAI, help/value-help, back, and terminal navigation.
- [x] Add tests for HTML source safety, keyboard navigation, labels, focus, and
  message announcements.
- [x] Add deterministic snapshots for representative selection, list, dynpro,
  ALV/tree, and HTML-viewer pages.
- [x] Add a manual smoke-test script covering a fresh session and two concurrent
  sessions to prove state isolation.

## 12. Compatibility, documentation, and rollout

- [x] Keep the existing text assertions running while HTML assertions are added.
- [x] Add a feature flag or explicit renderer mode only if compatibility requires
  it; document the default and removal criteria.
- [x] Add HTML result fields to all affected host result types without changing
  existing field meanings.
- [x] Update `scaffold/PLAN.md` only after the corresponding HTML behavior is
  implemented and verified; keep this plan as the HTML work ledger.
- [x] Document unsupported GUI features and their visible fallback in
  `ANORMALIES.md` when the limitation is caused by transpilation/runtime support.
- [x] Document public page/request types and the security model in `README.md`.
- [x] Add a focused npm script for HTML host tests.
- [x] Add HTML tests to the standard `npm test` path.
- [x] Add `git diff --check`, lint, transpilation, unit, integration, and browser
  verification to the completion checklist.
- [x] Run the downstream regression suite after the public host result contract
  stabilizes.
- [x] Mark this plan complete only when every checkbox above is checked and the
  current page can be rendered and interacted with for every supported host
  processor.

## Verification record

- [x] Run `git diff --check` after the HTML changes.
- [x] Run `npm test` (lint, transpilation, ABAP Unit, and the focused HTTP
  adapter test).
- [x] Run the HTML golden primitive and accessibility checks in ABAP Unit.
- [x] Run `node integration/html-http.mjs` and
  `node integration/html-smoke.mjs` independently.
- [x] Run `node integration/html-snapshots.mjs`.
- [x] Exercise stateful HTML round trips for nested selection, screen,
  submit-and-return, and transaction continuations in ABAP Unit.
- [x] Run the downstream regression suite to a passing result; on 2026-08-28
  the external abapGit checkout installed and its full `npm run unit` suite
  passed through the runner's Git Bash fallback on Windows.
- [x] Run browser-level verification on 2026-08-28 with the installed Chrome
  executable; `npm run test:html-browser` completed all selection, list,
  dynpro, help/value-help, back, and terminal interactions.

## Definition of done

- [x] `zcl_gg_host` returns a complete HTML document for selection, list,
  message, navigation, and terminal states.
- [x] `zcl_gg_host_dynpro` returns a complete HTML document for each visible
  dynpro state and preserves all supported control definitions.
- [x] Every dynamic value is escaped and every interactive action has a typed,
  validated request mapping.
- [x] Multi-request state is explicit, isolated, expirable, and covered by tests.
- [x] Existing structured and text compatibility tests remain green.
- [x] The supported `src/` GUI controls either render through the registry or
  have a documented, tested HTML fallback.
- [x] `npm test`, the focused HTML/browser suite, and downstream regression tests
  pass.
