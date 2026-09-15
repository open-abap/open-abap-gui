# gg-gui functional completion plan

PLAN9 closed with 50/50 semantic, behavioral, and visual gates green. A
measurement on 2026-09-15 showed that verdict is weaker than it reads: the three
gates can all be satisfied by a page that runs no converted program logic at
all.

Measured baseline, from `converter/gg-gui-validation/results.json`, the 50
generated classes, and a live dispatch against the validation host:

- 30 of 50 reports are genuinely converted and behave (`ALV_GRID` renders typed
  columns, totals, row colors, and a working toolbar from lowered logic).
- 20 of 50 are emitted by `emitPartialApplication`
  (`converter/src/emit/class-source.mjs`), which writes screen metadata only.
  Every `process_output_module` and `process_input_module` body is `RETURN.`.
  `ZGG_GUI_SALV_TABLE` is 504 source lines and 224 generated lines of `RETURN.`;
  its `CC_MAIN` container renders as an empty `<div>`, both status fields render
  empty, and none of its nine buttons does anything.
- 512 converter diagnostics remain: 227 `GGCONV-E511` control method, 161
  `GGCONV-E516` unsupported statement, 39 `GGCONV-E514` frontend, 37
  `GGCONV-E510` control construction, 27 `GGCONV-E515` dynamic type, 21
  `GGCONV-E512` event registration. The generated sources carry 440
  `* TODO GGCONV-` markers.
- 150 of the 408 audited journeys (37%) run against a class with no PAI.

Three mechanisms let that pass, and each is a work item below:

1. `apply_action_receipt` in `scaffold/host/zcl_gg_host_dynpro.clas.abap`
   injects `Action <UCOMM> processed` — and writes it into the program's own
   `GV_STATUS` — whenever the program produced no status. A dispatch of `SELECT`
   to `CV_SALV_TABLE` changes exactly that one string and nothing else, and the
   behavioral gate reads the changed page as `stateChanged: true`.
2. The visual gate's `control-types` check compares the rendered page against
   the same screen metadata that generated it, so a metadata-only shell is
   self-consistent by construction.
3. `converter/test/gg-gui.mjs` hardcodes a 29-name list choosing `preserve` vs
   `skeleton` per report, so which reports get real lowering is a constant in
   the test rather than an outcome of the converter.

The good news is that the missing runtime does not have to be written. `src/`
already ships the full SALV family (60 classes under `src/salv/`), the dynamic
document element family (`src/dd/`), and `src/dragdrop/`. The gap is in the
converter's allow-list and type resolution, not in control implementations.

## Definition of done

- [ ] No report's converted class has an empty module body where its dynpro
  metadata declares a PBO/PAI module. A screen that declares modules runs them.
- [ ] Every remaining `GGCONV-E5xx` diagnostic is a named capability boundary
  recorded in `fallback-audit.json` with evidence, not a silently dropped
  statement.
- [ ] The behavioral gate fails an inert screen. Removing a report's logic must
  turn its gate red.
- [ ] `converter/test/gg-gui.mjs` derives the conversion strategy from the
  converter result; the hardcoded program-name list is gone.
- [ ] Screen-painter text renders as SAP renders it: `Export XML`, not
  `Export_XML____`.
- [ ] Back/F3 reaches the running program when its CUA status activates BACK.
- [ ] Converter unit tests, gg-gui conversion/capture, scaffold lint, ABAP
  transpilation/unit tests, Playwright specs, and `git diff --check` pass for
  every batch.

## Phase 0 - make the gates able to fail

Do this first. Until a gate can go red, there is no way to distinguish progress
from regression, and the 20 hollow reports will keep reporting success.

- [ ] Gate the action receipt. `apply_action_receipt` may not invent a status
  for a program that produced none. Either drop the fallback entirely or put it
  behind an explicit host-diagnostic flag that the validation run turns off. A
  renderer-invented receipt is the same defect class as a renderer-invented
  button.
- [ ] Add a program-effect gate to the interaction audit: a journey passes only
  when the change is something the program owns — a declared field value, list
  or grid or tree content, a `MESSAGE` the program issued, a screen change it
  requested. A diff confined to host chrome is not a pass.
- [ ] Add a conversion-completeness gate: fail a report whose screen metadata
  declares modules while the generated class emits empty bodies for them.
- [ ] Remove the `partialStrategy` name list at `converter/test/gg-gui.mjs:798`.
  Strategy follows the converter's own `supported` result.
- [ ] Record the 20 currently hollow reports as a known-failing list so the
  first run after this phase is red by design and each later batch measurably
  shrinks it: `ALV_EDIT`, `ALV_EVENTS`, `ALV_TREE`, `CALENDAR`, `CFW_BASICS`,
  `COMPOSITE`, `DRAG_DROP`, `DYNAMIC_DOCUMENT`, `FRONTEND_SERVICES`,
  `HTML_VIEWER`, `ILI_DRAGDROP`, `MODAL_SELSCREEN`, `PICTURE`, `SALV_HIERSEQ`,
  `SALV_TABLE`, `SALV_TREE`, `TEXTEDIT`, `TIMER`, `TOOLBAR`, `TREES`.
- [ ] Keep the pixel diff as evidence only, unchanged. It is not the problem
  and must not become an acceptance contract.

## Phase 1 - converter coverage for the shipped control classes

Measured statement kinds behind the 512 diagnostics: 263 `Call`, 111 `Free`, 32
`CreateObject`, 21 `SetHandler`, 15 `Export`, 14 `FreeMemory`, 10 `TypePools`,
6 `Import`, and a tail of `Raise`, `Continue`, `Unassign`, `Sort`, `CreateData`,
`GetReference`, `Exit`.

- [ ] Extend `CONVERTIBLE_CONTROL_CLASSES`
  (`converter/src/passes/lower-statements.mjs:28`) to cover the classes the
  runtime actually ships. Missing families today: every `CL_SALV_*` class, the
  `CL_DD_*` element classes below `CL_DD_DOCUMENT`, and `CL_DRAGDROP` /
  `CL_DRAGDROPOBJECT`. Prefer deriving the set from an inventory of `src/`
  rather than hand-maintaining a literal, so the list cannot drift from the
  runtime again; keep the derivation offline and deterministic.
- [ ] Resolve receiver types for event-handler parameters. `controlObjectTypes`
  reads only `DATA` declarations, so `e_object`, `er_data_changed`,
  `e_dragdropobj`, and `menu` never resolve even though their classes are
  already convertible. Resolve them from the event signature of the owning class
  in the handler declaration (`FOR EVENT ... OF cl_gui_alv_grid`). This single
  fix reaches the ALV toolbar, data-change, and context-menu handlers across
  several reports.
- [ ] Lower `FREE` for any resolved control reference, including the
  `FREE: a, b, c.` chain form. 111 occurrences, and it is the statement that
  ends most control lifecycles in these reports.
- [ ] Lower `CREATE OBJECT` and `SET HANDLER` against hoisted local classes.
  `DATA go_events TYPE REF TO lcl_events.` plus
  `SET HANDLER go_events->on_added_function FOR lo_event_source.` is the shape
  every SALV and ALV report uses to register events, and it currently drops.
- [ ] Lower `EXPORT`/`IMPORT`/`FREE MEMORY` (35 occurrences) onto session-owned
  ABAP memory rather than dropping them; they carry state across the navigation
  the reports demonstrate.
- [ ] Resolve `TYPE-POOLS` (10 occurrences) against the shipped type pools
  (`sdydo`, `cndd`, and the DDIC set) instead of emitting a scaffold gap.
- [ ] Clear the small tail: `Raise`, `Continue`, `Unassign`, `Sort`,
  `CreateData`, `GetReference`, `Exit`.
- [ ] Add a minimal extracted fixture per new lowering rule, as PLAN9 Phase 1
  required. Do not copy whole gg-gui reports into fixtures.
- [ ] Re-split anything still unsupported into an actionable diagnostic with a
  suggestion that names the missing rule, so the remaining set stays a work
  list rather than a category.

## Phase 2 - screen text fidelity

`RPY_DYFATC` `<TEXT>` values are underscore-encoded: interior blanks become `_`
and the value is padded to `LENGTH` with `_`. The SAP reference for
`ZGG_GUI_SALV_TABLE` renders `Export XML`; the converted page renders
`Export_XML____`. There are 541 such texts across 38 program XMLs, so this is
visible on the 30 working reports too.

- [ ] Decode screen-painter text attributes when loading dynpro metadata: strip
  the padding to `LENGTH`/`VISLENGTH`, then restore interior blanks.
- [ ] Apply the decoding only to screen-painter text attributes. Never to field
  values, program data, text symbols, or selection texts.
- [ ] Verify a sample against the SAP reference captures rather than against the
  XML, since the XML is the lossy side.
- [ ] Add a converter fixture covering padded text, interior blanks, and a text
  that legitimately contains an underscore.

## Phase 3 - functional completion, report by report

Each item is done when the report's own logic runs, its controls hold real
content, its buttons change program-owned state, and its remaining diagnostics
are zero or recorded boundaries. Diagnostic counts are the current baseline.

**SALV family**

- [ ] **`ZGG_GUI_SALV_TABLE` (76):** container factory, generated columns,
  functions, formatting, five demo rows, and the added-function/double-click/
  link-click handlers. The report only shows its text fallback from a
  `CATCH cx_root`; with a working factory it must show the table. See Phase 5.
- [ ] **`ZGG_GUI_SALV_HIERSEQ` (55):** header/item binding, grouped blocks,
  quantities and currency, totals, classic toolbar and navigation.
- [ ] **`ZGG_GUI_SALV_TREE` (41):** hierarchy, per-cell item types, link and
  double-click events, add-leaf, selection, expand/collapse.

**Dynamic document and drag/drop**

- [ ] **`ZGG_GUI_DYNAMIC_DOCUMENT` (78):** the `CL_DD_*` element tree — table
  areas, form areas, input/select/button elements, links, icons — plus document
  metadata, callbacks, background changes, refresh in place, and print.
- [ ] **`ZGG_GUI_DRAG_DROP` (54):** `CL_DRAGDROP` flavors and effects, payload
  validation, reject, undo, keyboard parity, stable row/node ids.

**Frontend and ALV**

- [ ] **`ZGG_GUI_FRONTEND_SERVICES` (43):** explicit upload/download, clipboard
  permission, capability reporting, cleanup, auditable log. Never claim an
  operation the browser did not perform.
- [ ] **`ZGG_GUI_ALV_EVENTS` (25):** custom toolbar/menu, delayed selection,
  print, data-change protocol, drag/drop, application-event mode, hotspot and
  double-click into the report's event log. Mostly unblocked by the Phase 1
  event-parameter fix.
- [ ] **`ZGG_GUI_ALV_TREE` (17):** hierarchy plus typed columns, lazy children,
  node/item/context-menu events, calculation, mutation, totals, toolbar.
- [ ] **`ZGG_GUI_ALV_EDIT` (11):** editable cells, checkboxes, dropdowns, cell
  buttons, hotspots, F4, changed-data protocol, validation, insert/copy/delete,
  in-memory Save/Discard with no implied persistence.

**Containers, controls, editors**

- [ ] **`ZGG_GUI_CFW_BASICS` (18):** one control lifecycle covering focus,
  visibility, enablement, geometry, timer, refresh, reset, Back.
- [ ] **`ZGG_GUI_COMPOSITE` (17):** tree, application toolbar, ALV grid, text
  editor, and nested splitters together, with cross-control selection intact.
- [ ] **`ZGG_GUI_CALENDAR` (10):** nine-month layout, week numbers, marks,
  focus/selection distinction, range mode, navigation, bounds, locale-stable
  labels.
- [ ] **`ZGG_GUI_PICTURE` (9):** allow-listed image load with aspect/fit/
  alignment, alt text, loading and error state, offline fixture behavior.
- [ ] **`ZGG_GUI_TREES` (6):** column-tree hierarchy, item classes,
  expand/collapse/lazy load, selection, double-click, context menu, column
  visibility, mutation, opaque node keys.
- [ ] **`ZGG_GUI_HTML_VIEWER` (4):** URL policy, sandboxed content, navigation
  state, `sapevent` links routed to typed host actions.
- [ ] **`ZGG_GUI_TEXTEDIT` (4):** readonly, word wrap, font, cursor/selection,
  stream and table round trips, protected lines, clear/restore.
- [ ] **`ZGG_GUI_TOOLBAR` (2):** normal/toggle/menu/dropdown/disabled items,
  separators, state changes, context menus, overflow, keyboard use.
- [ ] **`ZGG_GUI_TIMER` (2):** session-owned start/stop, interval changes,
  instance reuse, tick count, cancellation on navigation, test clock.
- [ ] **`ZGG_GUI_ILI_DRAGDROP` (2):** keep the honest ActiveX-unavailable
  fallback, but render the fallback text, geometry/visibility/menu responses,
  and the non-terminating Back path that the reference shows.
- [ ] **`ZGG_GUI_MODAL_SELSCREEN` (1):** modal and fullscreen selection screen
  calls, explicit screen numbers, validation and cancel return codes, parent
  value retention.

## Phase 4 - shell gaps

- [ ] Dispatch Back/F3 to the running program when its CUA status activates
  `BACK`, falling back to the workbench otherwise. `render_commandbar`
  (`scaffold/zcl_gg_workbench_utility.clas.abap`) currently hardwires Back to
  the workbench form, so SE01/SE09/SE11/SE16/SE38, `zcl_gg_ex_058`,
  `zcl_gg_integration_dynpro`, and `zcl_gg_rich_dynpro_base` all handle
  `ucomm = 'BACK'` in PAI with no UI path to reach it. Their specs drive BACK
  through `/dispatch` to work around this.
- [ ] Replace the shipped `announce("F1: help todo")` stub in the shell script
  with real F1 routing, or remove the key handler until it does something. A
  `todo` string must not ship in the product shell.
- [ ] Re-audit the renderers for any other host-invented affordance in the same
  family as the action receipt: a control, message, or status the program never
  declared.

## Phase 5 - correct the fallback and reference audits

- [ ] Re-verify `ZGG_GUI_SALV_TABLE`'s entry in `fallback-audit.json`. It cites
  "the pinned open-abap-gui SALV factory currently terminates with an
  assertion", but `src/salv/cl_salv_table.clas.abap` now has a working `factory`
  with no assertions. Confirm end-to-end, then reclassify: if the factory works,
  the report must render the real table and the fallback is no longer an
  accepted outcome.
- [ ] Keep `ZGG_GUI_GRAPHICS` and `ZGG_GUI_ILI_DRAGDROP` as genuine capability
  boundaries, with their honest text actually rendered.
- [ ] Re-confirm the `ZGG_GUI_SUBSCREENS` and `ZGG_GUI_DIALOGS_HELP` reference
  identity question that PLAN9 Phase 0 closed, now that the gates can fail.
- [ ] Update `scaffold/GUI_HTML_CAPABILITIES.md` only after each contract is
  implemented and verified. Its SALV rows currently describe model methods as
  "safe no-ops"; that must match whatever Phase 3 actually delivers.

## Phase 6 - verification and rollout

- [ ] Per batch: `npm run lint`, `npm run unit`, `npm --prefix converter run
  test:unit`, `npm --prefix converter run test:gg-gui`, `npm run
  test:html-browser`, and `git diff --check`.
- [ ] Keep the known-failing list from Phase 0 current. Every batch removes
  entries; no batch adds one without a recorded reason.
- [ ] Add Playwright coverage for each report as it becomes functional, with
  negative cases for forged function codes, row/node ids, variants, paths, URLs,
  and disabled controls.
- [ ] Re-publish the comparison index with the pass/fail summary and the
  diagnostic count per report, so the remaining work stays visible.
- [ ] Accept a report only when it runs its own logic, holds real content, and
  passes the strengthened gates. A page that merely renders is not parity.

## Recommended delivery order

- [ ] **Batch A:** Phase 0 in full. Ends with a red baseline that measures the
  real gap.
- [ ] **Batch B:** Phase 1 control-class coverage and event-parameter type
  resolution, plus Phase 2 text decoding. These are shared fixes; expect them to
  clear a large share of the 512 diagnostics before any report-specific work.
- [ ] **Batch C:** SALV family and Phase 5 fallback correction.
- [ ] **Batch D:** dynamic document, drag/drop, frontend services.
- [ ] **Batch E:** ALV events/tree/edit and the container, editor, tree, and
  control reports.
- [ ] **Batch F:** Phase 4 shell gaps, then the full 50-report run,
  accessibility checks, documentation, and the final audit.
