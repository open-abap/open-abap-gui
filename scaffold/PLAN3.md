# HTML host rendering plan

This plan turns the scaffold host into a page renderer. The target is that a
report or dynpro execution produces a complete, safe HTML document for the
currently visible processor state, while retaining the existing structured
result and text-line output during migration.

The plan is intentionally implementation-sized: every checkbox is one reviewable
change with one observable result. Do not check a box until its focused test and
the repository verification command pass.

When the transpiler does not support a statement or construct, record the gap
in `scaffold/ANORMALIES.md`. Include the feature/report, the exact
statement, the transpiler error, and the verification date. Keep the related
checklist item open until the report passes the runtime gate, unless the plan
explicitly documents a different host or scaffold blocker.

## Current state and discovered gaps

- `scaffold/host/zcl_gg_host.clas.abap` drives report lifecycle callbacks and
  returns `ty_result`, but the result has no HTML or page-history field.
- `scaffold/host/zcl_gg_host_list.clas.abap` renders to right-trimmed strings.
  Format, title, status, hidden fields, and page metadata are stored separately;
  individual output fragments are not retained for semantic HTML rendering.
- `scaffold/host/zcl_gg_host_screen.clas.abap` records selection-screen
  structure, values, and states, but its generic element record drops some
  operation-specific data such as data types and fixed listbox values. It does
  not render a screen.
- `scaffold/host/zcl_gg_host_dynpro_builder.clas.abap` currently ignores all
  controls and only keeps the screen records. The flow builder similarly drops
  fields, subscreens, chains, and table-loop structure.
- `scaffold/host/zcl_gg_host_dynpro.clas.abap` returns text lines and the final
  screen only; it has no rendered screen model or HTML result.
- `scaffold/host/zcl_gg_host_session.clas.abap` hard-codes the report processor
  in `get_context`, and a new `run` creates a fresh execution. Browser requests
  therefore need an explicit state/session boundary before they can drive a page
  across multiple requests.
- `src/cl_abap_browser.clas.abap` and `src/cl_gui_html_viewer.clas.abap` expose
  HTML-related SAP APIs but are no-ops. The other GUI controls are also mostly
  stubs and are not connected to the scaffold host.
- There is no HTTP server or browser transport in this repository. The first
  deliverable should therefore be a transport-neutral HTML response from the
  ABAP host; an optional Node HTTP adapter can consume that contract afterward.

## Scope and invariants

- [ ] Define the first HTML contract as a complete document (`<!doctype
  html>`, `html`, `head`, `body`) returned by the host, not a partial fragment.
- [ ] Define the visible page kinds: selection screen, classic list, dynpro,
  message/error, and terminal/navigation result.
- [ ] Define whether a run returns only the current page or both the current page
  and an ordered page history; document the choice in the public result type.
- [ ] Define stable, namespaced HTML `id` and `name` rules from ABAP program,
  screen, control, list level, and row identifiers.
- [ ] Define the browser event envelope for submit, button, tab, list-line,
  function-code, value-help, field-help, and back actions.
- [ ] Define which state is server-owned and which values may be sent back by the
  browser; do not expose raw `HIDE` values or continuation internals by default.
- [ ] Define the compatibility policy for `lines`, `line_formats`, `elements`,
  `states`, and dynpro result fields while `html` is introduced.
- [ ] Define the supported HTML baseline (HTML5, UTF-8, no client framework,
  keyboard-accessible controls) and the allowed inline/style asset strategy.
- [ ] Define the security policy: escape text and attributes, reject unsafe URLs,
  prevent raw ABAP text from becoming markup, and avoid executable user data.
- [ ] Add a short architecture section to `README.md` linking to this plan and
  explaining that HTML rendering is transport-neutral.

## 1. Page, request, and response model

- [ ] Add a versioned page vocabulary interface for page kind, page id, session
  id, processor, title, status, and terminal state.
- [ ] Add typed page-action records containing action kind, user command, target
  control, target row, and opaque state token.
- [ ] Add a typed request record for session id, page id, action, input values,
  selected list line, cursor data, PF key, and help/value-request target.
- [ ] Add a typed response record containing current page, HTML document, page
  kind, page id, messages, and the structured compatibility result.
- [ ] Add a page collection type that preserves page order without requiring
  callers to parse HTML.
- [ ] Add an explicit renderer context carrying program, processor, screen/list
  level, locale-independent formatting settings, and CSP nonce if needed.
- [ ] Add a session lifecycle object with start, dispatch, render, and close
  operations; keep it separate from static variant storage.
- [ ] Add a deterministic session id and page id generator suitable for ABAP Unit.
- [ ] Add expiry/clear operations for host sessions so state cannot leak between
  repeated executions or tests.
- [ ] Add focused tests for request validation, unknown session, stale page id,
  unknown action, and terminal response behavior.

## 2. Safe HTML primitives and document shell

- [ ] Add one HTML escaping utility for text nodes and one for attribute values.
- [ ] Add safe URL validation for browser, picture, and link-like controls; reject
  `javascript:`, unsafe schemes, and untrusted markup URLs.
- [ ] Add attribute rendering that omits initial optional attributes and escapes
  every emitted value.
- [ ] Add element helpers for opening/closing tags, void tags, text nodes, and
  deterministic attribute ordering.
- [ ] Add a document-shell renderer with doctype, charset, viewport, title,
  base stylesheet, message region, and main content region.
- [ ] Add page-level `data-page-id`, `data-session-id` handling without putting
  private continuation state in visible HTML.
- [ ] Add a CSP-compatible style strategy and test that generated dynamic text
  cannot break out of an element or attribute.
- [ ] Add golden tests for empty, Unicode, quotes, ampersands, angle brackets,
  newlines, and long values.

## 3. Capture a complete classic-list render model

- [ ] Extend `zcl_gg_host_list` with a typed page/row model instead of deriving
  HTML from trimmed `mt_lines` after the fact.
- [ ] Record each write fragment's source text, rendered text, start column,
  width, justification, current format, and hidden-field association.
- [ ] Record checkbox, icon, and symbol fragments with semantic kind and display
  fallback separately from their text representation.
- [ ] Record explicit line breaks, skipped lines, underlines, and page boundaries
  as model events.
- [ ] Record list level, page number, line number, title, status, and navigation
  actions on the model.
- [ ] Preserve `READ LINE` and `MODIFY LINE` behavior when a line is represented
  by fragments rather than only a string.
- [ ] Preserve hidden values in host-owned state and give each selectable line an
  opaque action token.
- [ ] Preserve existing `finish_output` and `get_line_formats` behavior for all
  current tests.
- [ ] Add model tests for placement, gaps, fixed widths, justification, format
  changes, page breaks, hidden values, and line modification.

## 4. Render classic lists as HTML pages

- [ ] Add a list-page renderer that emits the title, status, page sections, and
  list body through the document shell.
- [ ] Render fixed-column output with a layout that preserves classic spacing and
  does not collapse repeated spaces on narrow screens.
- [ ] Render each output fragment with escaped text and its format classes/data
  attributes rather than applying formatting only to the whole line.
- [ ] Map classic colors, intensified, inverse, hotspot, input, and quickinfo to
  deterministic CSS classes and accessible text/title attributes.
- [ ] Render checkboxes, icons, symbols, and unknown icon names with visible,
  accessible fallbacks.
- [ ] Render `HIDE` lines as keyboard- and pointer-selectable actions while
  keeping hidden values out of the visible source and client payload where
  possible.
- [ ] Render `SET PF-STATUS`, excluded commands, titles, and function-code
  actions as page controls with disabled/excluded states.
- [ ] Render list-level navigation and back actions using the request envelope.
- [ ] Render page breaks as separate semantic sections with page metadata.
- [ ] Render informational, warning, error, abort, and exit messages in the
  correct accessible message region and severity style.
- [ ] Add HTML assertions for the existing examples 01–14 and 43–50.
- [ ] Add an interactive integration test that dispatches a rendered line action
  and receives the same detail-list semantics as the current text host.

## 5. Preserve and render selection-screen definitions

- [ ] Expand `zcl_gg_host_screen=>ty_element` or add typed element tables so all
  builder inputs survive: data type, visible length, fixed values, flags,
  `for_field`, modification groups, and screen identity.
- [ ] Preserve block nesting and associate each rendered element with its block,
  line, position, and source order.
- [ ] Preserve tabbed-block/tab relationships and the selected/default tab.
- [ ] Preserve named selection-screen metadata (`SCREEN nnn`, window,
  subscreen) instead of treating all screens as `1000`.
- [ ] Add a screen snapshot containing definition, current values, current states,
  messages, and available actions.
- [ ] Add tests proving that `AT SELECTION-SCREEN OUTPUT` mutations are reflected
  in the snapshot and that PAI mutations follow the documented lifecycle.

## 6. Render selection screens as HTML pages

- [ ] Add a selection-page renderer for parameters with labels, values, lengths,
  types, defaults, required state, lower-case state, and no-display state.
- [ ] Render checkboxes with checked state and associated user command.
- [ ] Render radio-button groups with one semantic group and checked state.
- [ ] Render listboxes with escaped fixed-value labels and selected keys.
- [ ] Render select-options as low/high/range rows with sign and option inputs,
  including `NO-EXTENSION` and `NO-INTERVALS` restrictions.
- [ ] Render comments, labels, underlines, skips, explicit positions, and line
  groups without losing source order.
- [ ] Render blocks as `fieldset`/`legend` when framed and as accessible groups
  when not framed.
- [ ] Render pushbuttons, function keys, tabs, and screen/window actions as
  page actions carrying their ABAP user commands.
- [ ] Render field help and value-help affordances only when the corresponding
  state permits them.
- [ ] Add accessible error association from messages to the affected field/row.
- [ ] Add a form serializer/parser mapping HTML names back to typed host values
  and ranges without changing ABAP field names.
- [ ] Add request-dispatch tests for submit, cancel/exit, pushbutton, tab,
  value-help, help, radio group, and range actions.
- [ ] Add HTML assertions for examples 15–38 and the selection integration suite.

## 7. Capture and render dynpro definitions

- [ ] Extend `zcl_gg_host_dynpro_builder` to retain every typed control in screen
  and source order instead of returning from the control methods.
- [ ] Retain positions, dimensions, modification ids, data types, required flags,
  value-help flags, password flags, fixed values, and user commands.
- [ ] Retain table-control columns, widths, input flags, required flags, and
  visible-row settings.
- [ ] Retain tabstrip/tab, box, subscreen-area, custom-control, and nested screen
  relationships.
- [ ] Extend `zcl_gg_host_dynpro_flow` to retain fields, modules, chains,
  table-loop context, subscreen calls, POV, and POH in execution order.
- [ ] Add a typed dynpro snapshot containing screen definition, current values,
  current states, flow metadata, title, status, cursor, and messages.
- [ ] Make session context report the active processor (`DYNPRO`, `LIST`, or
  `SELECTION`) and active screen/list level during each callback.
- [ ] Add builder and flow tests proving that no supported definition operation is
  silently discarded.

## 8. Render dynpros as HTML pages

- [ ] Add a dynpro-page renderer using screen dimensions and a responsive CSS
  coordinate system with a documented pixel/grid conversion.
- [ ] Render input and output fields with typed values, labels, enabled/visible/
  required state, uppercase/password behavior, and value-help affordances.
- [ ] Render pushbuttons, checkboxes, radio buttons, listboxes, boxes, and text
  controls with their user commands and accessible labels.
- [ ] Render tabs and subscreens with stable targets and correct selected state.
- [ ] Render table controls with headings, rows, scrolling metadata, and input
  cells while preserving table-control names and row indexes.
- [ ] Render custom controls as explicit named placeholders with an extension
  point instead of silently dropping them.
- [ ] Render title, status, cursor focus, and modal/window metadata.
- [ ] Map form submissions to PAI module context, including field, row, cursor,
  user command, and table-loop information.
- [ ] Drive PBO before each rendered screen and PAI only for a submitted action.
- [ ] Drive POV/POH actions and return their values/help as HTML page state.
- [ ] Implement repeated screen transitions, back, leave-screen, leave-to-screen,
  and terminal transitions in the session object.
- [ ] Add HTML assertions for dynpro integration scenarios and example 58.
- [ ] Add a browser-level round-trip test for input → PAI → returned screen.

## 9. Navigation, continuations, messages, and multi-page execution

- [ ] Represent `CALL SELECTION-SCREEN`, `CALL SCREEN`, `SUBMIT ... AND RETURN`,
  and `CALL TRANSACTION` as page transitions with resumable state.
- [ ] Represent terminal `SUBMIT`, `LEAVE PROGRAM`, and `LEAVE TO TRANSACTION`
  as terminal HTML responses with no false continuation action.
- [ ] Render a navigation/history surface only when it corresponds to a valid
  host-owned continuation; do not infer navigation from arbitrary HTML.
- [ ] Preserve list memory output as a structured page snapshot as well as the
  existing text table.
- [ ] Preserve variant behavior across requests without sharing report execution
  state between sessions.
- [ ] Render message `DISPLAY LIKE` separately from message control flow so an
  error remains an error even when displayed with another style.
- [ ] Add tests for nested selection, nested dynpro, submit-and-return, list
  memory, transaction return, terminal navigation, and message retry.
- [ ] Add stale-session, duplicate-submit, back-after-terminal, and invalid-token
  tests.

## 10. Connect existing GUI controls to the HTML host

This phase covers the separate `src/` compatibility classes. It must not make
the scaffold report renderer depend on concrete GUI classes; use a host control
registry/adapter boundary instead.

- [ ] Inventory every concrete GUI class and mark each method as model, render,
  event, or intentional no-op in a maintained capability table.
- [ ] Add a host control registry keyed by control id and parent/container id.
- [ ] Make `cl_gui_object`/`cl_gui_control` retain identity, parent, geometry,
  enabled, visible, focus, and lifetime state needed by the registry.
- [ ] Make container classes retain child order and containment.
- [ ] Render custom containers, docking containers, dialog boxes, splitters, and
  easy splitters as HTML layout regions.
- [ ] Render `cl_gui_textedit` as an accessible textarea with get/set/selection
  state and change actions.
- [ ] Render `cl_gui_picture` as a safe image element with size and alignment.
- [ ] Render `cl_gui_toolbar` as an accessible toolbar with enabled/disabled
  buttons and command actions.
- [ ] Render `cl_gui_calendar` and selector controls with HTML form controls and
  ABAP-compatible values.
- [ ] Render ALV grid data, columns, sorting/filtering/selection metadata, and
  toolbar actions as a semantic table page.
- [ ] Render tree controls with nested lists, expansion state, node selection,
  drag/drop capability flags, and actions.
- [ ] Render SALV-backed list/table/tree models through the same page renderer.
- [ ] Render graphics/chart objects through a documented HTML/SVG or fallback
  representation without introducing unsafe raw SVG.
- [ ] Implement `cl_gui_html_viewer` against the registry/page store so
  `load_data`, `show_data`, `show_url`, navigation, and refresh have observable
  host behavior.
- [ ] Implement `cl_abap_browser=>show_html` as a host page/modal request and
  preserve title, container, dialog, and printing flags.
- [ ] Define intentional behavior for frontend services, timers, drag/drop, and
  progress indicators when no browser equivalent exists.
- [ ] Add control-level tests for lifecycle, geometry, visibility, events, and
  safe content handling.
- [ ] Add one end-to-end fixture combining a report, container, ALV/tree/text
  control, and HTML viewer in one rendered page.

## 11. Transport adapter and browser verification

- [ ] Decide whether the first transport is a Node `http` adapter, an embedding
  API, or both; record the decision and its session ownership rules.
- [ ] Add a minimal transport adapter that maps GET/start and POST/dispatch to the
  typed host request/response contract without embedding ABAP lifecycle logic.
- [ ] Add content-type, charset, cache, and error responses for the adapter.
- [ ] Add a sample page launcher using only repository dependencies or document the
  explicit extra dependency if one is unavoidable.
- [ ] Add browser tests for initial selection page, form submit, list selection,
  dynpro PAI, help/value-help, back, and terminal navigation.
- [ ] Add tests for HTML source safety, keyboard navigation, labels, focus, and
  message announcements.
- [ ] Add deterministic snapshots for representative selection, list, dynpro,
  ALV/tree, and HTML-viewer pages.
- [ ] Add a manual smoke-test script covering a fresh session and two concurrent
  sessions to prove state isolation.

## 12. Compatibility, documentation, and rollout

- [ ] Keep the existing text assertions running while HTML assertions are added.
- [ ] Add a feature flag or explicit renderer mode only if compatibility requires
  it; document the default and removal criteria.
- [ ] Add HTML result fields to all affected host result types without changing
  existing field meanings.
- [ ] Update `scaffold/PLAN.md` only after the corresponding HTML behavior is
  implemented and verified; keep this plan as the HTML work ledger.
- [ ] Document unsupported GUI features and their visible fallback in
  `ANORMALIES.md` when the limitation is caused by transpilation/runtime support.
- [ ] Document public page/request types and the security model in `README.md`.
- [ ] Add a focused npm script for HTML host tests.
- [ ] Add HTML tests to the standard `npm test` path.
- [ ] Add `git diff --check`, lint, transpilation, unit, integration, and browser
  verification to the completion checklist.
- [ ] Run the downstream regression suite after the public host result contract
  stabilizes.
- [ ] Mark this plan complete only when every checkbox above is checked and the
  current page can be rendered and interacted with for every supported host
  processor.

## Definition of done

- [ ] `zcl_gg_host` returns a complete HTML document for selection, list,
  message, navigation, and terminal states.
- [ ] `zcl_gg_host_dynpro` returns a complete HTML document for each visible
  dynpro state and preserves all supported control definitions.
- [ ] Every dynamic value is escaped and every interactive action has a typed,
  validated request mapping.
- [ ] Multi-request state is explicit, isolated, expirable, and covered by tests.
- [ ] Existing structured and text compatibility tests remain green.
- [ ] The supported `src/` GUI controls either render through the registry or
  have a documented, tested HTML fallback.
- [ ] `npm test`, the focused HTML/browser suite, and downstream regression tests
  pass.
