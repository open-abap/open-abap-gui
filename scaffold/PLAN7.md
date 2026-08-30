# Expanded example catalog plan

This plan grows the example catalog beyond the 58 classic-report parity
specimens. The next examples should demonstrate the framework as an application
platform: browser-visible controls, stateful interaction, accessibility,
navigation, error recovery, and realistic compositions.

The reserved range is `59` through `150`. Numbers are stable once an example
lands. Do not renumber later examples to fill an abandoned slot; document why a
slot was retired instead.

PLAN6 owns the application icon-bar implementation. PLAN7 references that work
but does not duplicate its renderer changes.

## Labels used below

- **Ready** — implementable through the current public scaffold contracts.
- **Extend** — requires a small, named public-contract or host-model extension
  before the example can be completed.
- **Fallback** — demonstrates an intentional browser-safe compatibility result,
  including an explicit no-op where desktop behavior cannot be reproduced.
- **Composite** — intentionally combines earlier atoms into one realistic flow;
  use only after its component examples pass.

These labels describe implementation sequencing, not completion. Every item
below starts unchecked.

## Non-negotiable rules

- [ ] Every example implements `zif_gg_transaction_v1` and publishes
  `ZGG_EX_<nn>` plus a concise, user-facing description beside its executable
  implementation.
- [ ] Use `zif_gg_report_v1` or `zif_gg_dynpro_v1`, never both, except in a
  local negative test that proves registry rejection.
- [ ] Keep one principal behavior per Ready/Extend example. Composite examples
  may combine only already-covered behaviors and must name their dependencies.
- [ ] Add `zgg_ex_<nn>.prog.abap` when a meaningful classic ABAP counterpart
  exists. For browser-only host behavior, document why no honest classic report
  counterpart exists instead of fabricating one.
- [ ] Add `zcl_gg_ex_<nn>.clas.testclasses.abap` for every example. ABAP Unit
  owns application state and host semantics; Playwright owns the real browser
  and HTTP boundary.
- [ ] Do not make JavaScript interpret ABAP controls, statuses, variants,
  navigation, or callbacks. JavaScript remains transport and browser testing.
- [ ] Never add renderer-specific HTML to an example. Examples define typed
  state; the shared host renders and validates it.
- [ ] Every interactive example includes one allowed action and one rejected,
  stale, disabled, malformed, or otherwise negative action where applicable.
- [ ] Every new dynamic string is tested with hostile text at its HTML boundary.
- [ ] An Extend example remains unchecked until the extension has focused tests,
  the example uses it, and no private test seam substitutes for the public API.
- [ ] A Fallback example states the SAP behavior, browser behavior, and visible
  fallback in `GUI_HTML_CAPABILITIES.md` or `ANORMALIES.md` as appropriate.
- [ ] Update the shared transaction inventory once per completed batch rather
  than adding one browser inventory assertion per example.

## Batch definition of done

A batch is complete only when:

1. Every example class and applicable classic report exists.
2. Every transaction is discoverable through the registry and launches by
   tcode rather than a class-name URL.
3. Focused ABAP Unit tests pass for every example in the batch.
4. Representative browser tests cross Express, the ICF shim, the real ABAP HTTP
   handler, and the real host runtime.
5. `npm run lint`, `npm run unit`, `npm run test:html-e2e`, and the clean
   repository checks pass.

---

## Phase 8 — Application shell and status (`59`–`66`)

- [ ] **59 — Ready after PLAN6: example-owned icon bar.** Define ordered
  `Refresh` and `Print` actions in the example status and prove that no
  workbench fallback icons appear.
- [ ] **60 — Ready after PLAN6: icon separators and accessibility.** Mix normal
  entries and separators; assert source order, accessible names, tooltips,
  focus order, and absence of separator actions.
- [ ] **61 — Ready: active, inactive, and excluded commands.** Show enabled,
  disabled, and active-but-excluded function codes, then prove forged requests
  are rejected without advancing the page.
- [ ] **62 — Ready: status changes after a command.** Start with one active
  action, handle it, and return a page whose status enables a different action
  and disables the first.
- [ ] **63 — Ready: declared PF keys.** Enable PF5 through `active_pf_keys`,
  handle it, reject PF6, and retain the original page after rejection.
- [ ] **64 — Ready: title, status, cursor, and command feedback.** Change the
  title and status text together and place focus on the control responsible for
  the next action.
- [ ] **65 — Extend: application breadcrumbs.** Add typed breadcrumb/navigation
  context to the page model; render it without deriving hierarchy from URLs.
- [ ] **66 — Ready: Unicode and hostile shell text.** Exercise RTL text,
  combining characters, emoji, quotes, ampersands, and angle brackets in title,
  status, labels, and messages.

## Phase 9 — Rich selection screens (`67`–`82`)

- [ ] **67 — Ready: typed date, time, integer, decimal, and character
  parameters.** Demonstrate external formatting and typed callback values.
- [ ] **68 — Ready: dynamic visible/input/required state.** Toggle a dependent
  field during `AT SELECTION-SCREEN OUTPUT` and verify HTML attributes and
  server validation agree.
- [ ] **69 — Ready: checkbox-controlled field group.** A checkbox enables a
  group, retained values survive disabling, and disabled browser fields cannot
  forge an accepted update.
- [ ] **70 — Ready: radio-driven blocks.** Change visible blocks and validation
  rules from a radio group while retaining the selected option.
- [ ] **71 — Ready: dependent listboxes.** Selecting a carrier changes the
  connection choices on the next output cycle without accepting stale options.
- [ ] **72 — Ready: include/exclude select-option ranges.** Exercise `I/E` with
  `EQ`, `BT`, and `CP` and show the resulting database selection.
- [ ] **73 — Extend: multiple select-option rows.** Add, remove, reorder, and
  validate multiple range rows through typed actions rather than encoded field
  names alone.
- [ ] **74 — Extend: selection multiple-choice dialog.** Open the browser
  equivalent of the SAP multiple-selection dialog and round-trip several
  ranges without exposing private host state.
- [ ] **75 — Ready: tabbed selection state retention.** Switch tabs, modify
  values on both pages, and prove all values remain server-owned and consistent.
- [ ] **76 — Ready: selection-screen pushbutton workflow.** Use a pushbutton to
  derive values, return to the same screen, and reject an undeclared function
  code.
- [ ] **77 — Ready: selection function keys.** Define two function keys with
  distinct commands and verify their state changes before execution.
- [ ] **78 — Ready: field and range value help.** Return multiple typed choices,
  select one, cancel another, and preserve the untouched field.
- [ ] **79 — Ready: contextual field help.** Render long help text, associate it
  with the correct field, and preserve focus and entered values.
- [ ] **80 — Ready: field, block, radio, and end-of-range validation order.**
  Record callback order and stop at the first error exactly once.
- [ ] **81 — Ready: error recovery and focus.** Reject input, retain all valid
  sibling values, focus the failing field, correct it, and continue.
- [ ] **82 — Composite: variant manager selection screen.** Save, list, load,
  overwrite, and delete variants from one screen using the existing variant
  store and explicit confirmation messages.

## Phase 10 — Advanced classic-list interaction (`83`–`98`)

- [ ] **83 — Ready: multi-level drill-down.** Navigate basic list to detail to
  subdetail, then Back twice while restoring each list level and its cursor.
- [ ] **84 — Ready: independent hidden values per row.** Use two hidden fields
  on repeated display text and prove the opaque row token restores the correct
  server values.
- [ ] **85 — Ready: command-driven refresh.** Change report state through an
  active command and redraw the list without accepting a replay of the old
  page.
- [ ] **86 — Ready: multiple `MODIFY LINE` operations.** Change text and format
  on several rows while preserving fragment boundaries and hidden values.
- [ ] **87 — Ready: fragment-level colors and emphasis.** Mix colors,
  intensified, inverse, hotspots, and reset behavior within one line.
- [ ] **88 — Ready: icons, symbols, checkboxes, and quickinfo.** Render semantic
  fallbacks, accessible labels, and hostile quickinfo safely.
- [ ] **89 — Ready: fixed-width numeric/date columns.** Compare right/left/center
  justification, zero values, overflow, rounding, and locale-independent output.
- [ ] **90 — Ready: Unicode wide-list layout.** Exercise CJK, RTL, emoji, and
  combining characters without corrupting logical columns or HTML escaping.
- [ ] **91 — Ready: automatic page breaks.** Combine line count, top-of-page,
  end-of-page, reserve, and blank-line policy across several pages.
- [ ] **92 — Extend: browser list paging controls.** Map first/previous/next/last
  commands to server-owned list pages and reject paging outside valid bounds.
- [ ] **93 — Extend: list search and find-next.** Store the search term in the
  session, move the cursor deterministically, and announce no-match results.
- [ ] **94 — Extend: list print view.** Produce a dedicated print representation
  without mutating the interactive list session or trusting browser markup.
- [ ] **95 — Extend: list download.** Return a typed download response with safe
  filename, content type, and CSV escaping; do not route it through raw HTML.
- [ ] **96 — Ready: stacked success/warning/error messages on a list.** Preserve
  order, display-like semantics, roles, and field-independent announcements.
- [ ] **97 — Ready: submitted list memory isolation.** Run two nested submits,
  retrieve each list, and prove neither overwrites the caller's visible list.
- [ ] **98 — Composite: flight list workbench.** Filter, sort, drill down,
  refresh, return, and retain selection state using only previously completed
  list examples.

## Phase 11 — Dynpro flow and controls (`99`–`116`)

- [ ] **99 — Ready: complete basic dynpro controls.** Render input, output,
  text, pushbutton, checkbox, radio, listbox, and box controls on one screen.
- [ ] **100 — Ready: PBO/PAI field transport.** Derive output during PBO,
  edit input, process PAI, and display the accepted server value.
- [ ] **101 — Ready: cursor and focused error field.** Set the cursor during
  PBO, reject PAI, and return focus to the failing field and row.
- [ ] **102 — Ready: POV and POH for dynpro fields.** Open typed value/help
  responses, choose/cancel, and preserve the rest of the screen.
- [ ] **103 — Ready: dynamic screen states.** Change visible, enabled, required,
  and display-only state in PBO and reject forged values for disabled controls.
- [ ] **104 — Ready: CHAIN validation.** Group fields, reject an inconsistent
  pair, and re-enable the entire chain for correction.
- [ ] **105 — Ready: table control display.** Render columns, visible rows,
  current line, and loop context with stable row identities.
- [ ] **106 — Extend: editable table control.** Edit multiple cells, validate a
  row, preserve other rows, and bind errors to the correct cell.
- [ ] **107 — Extend: table-control scrolling.** Page/scroll server-owned rows
  without trusting a client-provided absolute index.
- [ ] **108 — Ready: subscreen call.** Execute parent and subscreen PBO/PAI in
  defined order and isolate identically named fields by container.
- [ ] **109 — Ready: tabstrip with subscreens.** Switch tabs, retain both
  subscreen states, and reject an unknown tab or target screen.
- [ ] **110 — Ready: modal dialog screen.** Use `CALL SCREEN ... STARTING/ENDING`
  positions, return a value, and restore the parent screen.
- [ ] **111 — Ready: nested screen calls.** Call a second modal from the first,
  unwind continuations in order, and preserve parent state.
- [ ] **112 — Ready: SET SCREEN versus LEAVE TO SCREEN.** Demonstrate next-screen
  scheduling, immediate transfer, and loop protection.
- [ ] **113 — Ready: Back, Exit, and Cancel semantics.** Give each command a
  distinct result and prove disabled alternatives cannot be forged.
- [ ] **114 — Ready: message E/W/S behavior in PAI.** Retain screen values on
  errors, continue on success, and announce warning/display-like state.
- [ ] **115 — Ready: dynpro status changes by screen.** Each screen owns a
  different title, icon bar, active commands, excluded commands, and PF keys.
- [ ] **116 — Composite: two-screen flight editor.** Edit a header and table
  rows, use help, validate, confirm, save, and return to a summary list.

## Phase 12 — Containers and classic GUI controls (`117`–`134`)

- [ ] **117 — Ready: custom container.** Create a named container, attach one
  child, and prove identity, parentage, visibility, and accessible region name.
- [ ] **118 — Ready: splitter container.** Build nested horizontal/vertical
  panes with deterministic child order and responsive fallback layout.
- [ ] **119 — Ready: easy splitter.** Demonstrate the simplified two-pane API
  and retained sizing intent.
- [ ] **120 — Ready: docking container.** Exercise dock side, extension, and a
  semantic browser region when exact desktop docking is unavailable.
- [ ] **121 — Ready: dialog-box container.** Render titled modal content, focus
  containment, close action, and return focus.
- [ ] **122 — Ready: text editor.** Load multiline text, edit it, preserve
  newlines, report modified state, cursor, and selection.
- [ ] **123 — Ready: readonly text editor.** Render large Unicode content and
  reject forged edits to readonly state.
- [ ] **124 — Ready: picture control.** Show safe relative/data image sources,
  size/alignment, alternative text, and rejection of unsafe schemes.
- [ ] **125 — Ready: GUI toolbar.** Define buttons, separators, disabled state,
  labels, icons, and commands independently of the shell icon bar.
- [ ] **126 — Ready: calendar.** Select a date, enforce minimum/maximum bounds,
  and round-trip browser-native date input to ABAP format.
- [ ] **127 — Ready: selector.** Populate choices, change selection, retain it,
  and reject an unknown submitted key.
- [ ] **128 — Ready: sandboxed HTML viewer.** Load escaped `srcdoc`, navigate to
  an allow-listed URL, refresh, and prove scripts/unsafe schemes cannot run.
- [ ] **129 — Ready: dynamic document.** Compose headings, text, links, inputs,
  buttons, selects, forms, and tables with all user text escaped.
- [ ] **130 — Extend: dynamic-document event dispatch.** Convert link/button
  events into typed host actions instead of inline JavaScript callbacks.
- [ ] **131 — Ready: nested control registry.** Combine container, splitter,
  editor, picture, and toolbar; assert stable nesting and no duplicate IDs.
- [ ] **132 — Ready: control refresh across pages.** Update control snapshots
  after a command and prove a second session cannot see the first session's
  control state.
- [ ] **133 — Extend: control-level validation messages.** Associate messages
  with GUI-control identities and table cells rather than selection/dynpro
  fields only.
- [ ] **134 — Composite: document viewer/editor.** Browse a tree, open content
  in an editor/viewer pane, modify it, and confirm unsaved navigation.

## Phase 13 — ALV, trees, SALV, and graphics (`135`–`150`)

- [ ] **135 — Ready: ALV grid with field catalog.** Render typed columns,
  headings, output lengths, row data, zebra pattern, and empty-table behavior.
- [ ] **136 — Extend: editable ALV grid.** Edit cells, return a changed-data
  protocol, reject invalid values, and preserve valid edits.
- [ ] **137 — Extend: ALV sort and filter commands.** Apply typed multi-column
  sorts and filters server-side and show the active criteria.
- [ ] **138 — Extend: ALV row/cell selection.** Select rows and cells with opaque
  tokens and deliver typed selection events to ABAP.
- [ ] **139 — Extend: ALV toolbar events.** Add application functions, enforce
  active/excluded status, and dispatch toolbar commands through the host.
- [ ] **140 — Ready: simple tree.** Render parent/child nodes, expanded and
  selected state, hidden nodes, and safe node text.
- [ ] **141 — Ready: list and column trees.** Demonstrate item columns, headers,
  node icons, hierarchy, and semantic fallback layout.
- [ ] **142 — Extend: interactive tree events.** Expand/collapse and select
  nodes through opaque keys, rejecting unknown or cross-session keys.
- [ ] **143 — Ready: ALV tree.** Combine hierarchy with field-catalog columns
  and prove deterministic ordering.
- [ ] **144 — Ready: SALV table basics.** Use `cl_salv_table=>factory`, columns,
  display settings, functions, and semantic table output.
- [ ] **145 — Extend: SALV sort, filter, aggregation.** Demonstrate subtotal and
  total rows with server-owned sort/filter state.
- [ ] **146 — Ready: SALV header and layout forms.** Compose header info, labels,
  text, grid, and flow layouts above the table.
- [ ] **147 — Extend: SALV selections and events.** Select rows and dispatch a
  typed double-click/link event without browser-generated business state.
- [ ] **148 — Ready/Fallback: bar chart.** Render labelled series and values as
  an accessible figure/table fallback without raw SVG from application data.
- [ ] **149 — Ready/Fallback: chart engine and graphic presentation.** Preserve
  payload/title intent and expose a deterministic accessible fallback.
- [ ] **150 — Composite: analytics cockpit.** Combine selection filters, SALV or
  ALV table, tree navigation, chart summary, example-owned actions, and a
  detail dynpro using only completed component examples.

---

## Deferred compatibility demonstrations

These should receive numbers only after a browser contract exists. They are
valuable, but allocating stable example numbers before the contract is defined
would encourage false behavior.

- [ ] **Frontend file open/save.** Define upload/download contracts instead of
  returning a fabricated local filesystem path.
- [ ] **Clipboard.** Require an explicit browser permission/action boundary and
  never report success when no clipboard operation occurred.
- [ ] **Timer.** Define ownership, cancellation, session expiry interaction, and
  deterministic test time before exposing callbacks.
- [ ] **Progress indicator.** Define streaming/polling semantics and accessible
  announcements rather than retaining only the last requested percentage.
- [ ] **Browser navigation service.** Reuse safe URL policy and distinguish
  same-page links, new-window requests, and rejected schemes.
- [ ] **Drag and drop.** Define opaque source/target identities, keyboard
  equivalent actions, ordering, and cross-session rejection.
- [ ] **Drag/drop object payload.** Keep application payload server-side and
  submit only opaque tokens.
- [ ] **File-directory chooser compatibility.** Provide an explicit unsupported
  result unless a sandboxed virtual filesystem contract is introduced.
- [ ] **Desktop execute/shell calls.** Remain unsupported in the browser host;
  demonstrate a visible rejection, never a successful no-op.

## Recommended implementation batches

1. **Batch A — 59–66:** finish PLAN6 and establish shell/status ownership.
2. **Batch B — 67–82:** deepen selection screens and variants.
3. **Batch C — 83–98:** make classic lists feel like a complete application
   surface.
4. **Batch D — 99–116:** complete dynpro flow before adding complex controls.
5. **Batch E — 117–134:** exercise every existing GUI-control snapshot family.
6. **Batch F — 135–149:** harden structured tables, trees, and graphics.
7. **Batch G — 150:** build the analytics cockpit only after all dependencies
   are green.

Do not implement all batches as one change. Each batch should leave the catalog
runnable and the inventory exact.

## Final verification ledger

- [ ] The registry inventory contains every completed tcode exactly once and no
  reserved-but-unimplemented entry.
- [ ] Workbench descriptions state the observable feature rather than an
  internal class or interface name.
- [ ] Ready examples use only existing public contracts.
- [ ] Extend examples have focused contract/host tests before their example
  tests.
- [ ] Composite examples depend only on completed atomic examples.
- [ ] Every interactive action is authorized from the current server-owned page
  and rejected actions leave that page usable.
- [ ] Every control has an accessible name, keyboard path, and visible focus.
- [ ] Every dynamic text, attribute, URL, icon name, token, and download
  filename crosses a tested safety boundary.
- [ ] Browser tests remain representative rather than duplicating all ABAP Unit
  behavior.
- [ ] All open fallbacks and runtime/transpiler limitations are documented.
- [ ] The complete clean-checkout CI suite passes on Linux.
