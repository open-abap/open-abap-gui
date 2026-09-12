# gg-gui conversion and visual-parity plan

This plan is based on a filename-for-filename comparison of the 50 browser
screenshots in `converter/gg-gui-validation/screenshots/` with the 50 SAP GUI
reference screenshots in
`converter/gg-gui-validation/repository/sap-screenshots/`.

The current conversion test succeeds as a safety test, but not yet as an
application-parity test. Every generated image is a 1440 x 900 open-abap shell
containing report-specific converter diagnostics. Every reference image is a
1299 x 1009 SAP GUI capture containing the report's actual selection screen,
classic list, dynpro, control, ALV, tree, or intentional capability fallback.
The generated images therefore differ in content and behavior before color,
spacing, and typography are considered.

The reference set is not uniformly a picture of ideal behavior. `SALV_TABLE`,
`GRAPHICS`, and `ILI_DRAGDROP` visibly document unavailable native controls and
are legitimate fallback targets. `SUBSCREENS` and `DIALOGS_HELP` appear to have
stale or misidentified reference captures (tabstrip/program-execution content),
so their identity must be verified before treating pixels as an acceptance
contract.

## Definition of done

- [ ] Convert all 50 reports without replacing their application UI with the
  generic partial-conversion diagnostic page.
- [ ] Keep unsupported native operations honest and non-terminating, with the
  report's own explanatory fallback, status, and available actions intact.
- [ ] Make every reference action that is meaningful in a browser change
  server-owned state, update the visible UI, and preserve Back/Exit/Cancel
  semantics.
- [ ] Match the reference information hierarchy, control type, field order,
  grouping, density, alignment, visible state, and initial focus for every
  report; use accessible web-native rendering rather than copied SAP bitmap
  chrome.
- [ ] Capture all browser comparisons at one fixed viewport, locale, timezone,
  font set, dataset, and animation state.
- [ ] Add automated structural and behavioral assertions for every report and
  representative visual-regression assertions for every shared renderer.
- [ ] Leave generated sources, manifests, cloned reference data, screenshots,
  contact sheets, and pixel diffs under the existing gitignored
  `converter/gg-gui-validation/` tree.

## Phase 0 - make the comparison reproducible

- [ ] Extend `converter/test/gg-gui.mjs` to write a comparison index with the
  generated image, reference image, optional diff image, conversion status,
  diagnostics, and reference dimensions on one card per report.
- [ ] Reuse the existing screenshot-diff implementation instead of introducing
  a second pixel engine, but allow separate native-reference and browser image
  dimensions and a documented content-region crop.
- [ ] Fix the browser capture at 1299 x 1009 or record the deliberate viewport
  transform in the comparison metadata; do not compare a 1440 x 900 browser
  page to a 1299 x 1009 desktop capture without normalization.
- [ ] Freeze dates, times, user names, local paths, URLs, and sample rows so
  `HVAM`, timestamps, temporary directories, and current dates do not create
  false visual changes.
- [ ] Define three comparison gates per report: semantic content, interactive
  behavior, and visual structure. Pixel similarity alone must not pass a
  non-working control.
- [ ] Verify the provenance and intended screen state of `ZGG_GUI_SUBSCREENS`
  and `ZGG_GUI_DIALOGS_HELP`; replace stale reference images upstream or mark
  the correct initial state explicitly before accepting a visual result.
- [ ] Record intentional reference fallbacks for `ZGG_GUI_SALV_TABLE`,
  `ZGG_GUI_GRAPHICS`, and `ZGG_GUI_ILI_DRAGDROP` so future work does not replace
  honest capability messages with fake native success.

## Phase 1 - remove the converter-wide content blocker

The 50 generated manifests currently contain 1,921 `GGCONV-E501`, 170
`GGCONV-E301`, 60 `GGCONV-E204`, and 34 `GGCONV-E305` unsupported-feature
entries. These are occurrences rather than unique root causes; shared lowering
work should eliminate them family by family.

- [ ] Add report-owned dynpro metadata loading from `.prog.xml` and all matching
  `.prog.screen_NNNN.abap` files, including screen geometry, attributes,
  elements, flow logic, GUI status, titlebar, subscreens, and next-screen
  relationships.
- [ ] Define a report-plus-screen-provider contract so a converted executable
  report can expose dynpros without violating the existing single application
  kind and registry rules.
- [ ] Lower global `TYPES`, structured types, ranges, internal tables, constants,
  field symbols, and data declarations into legal class-pool scopes while
  preserving initialization order.
- [ ] Resolve the DDIC types used by gg-gui (`LVC`, `SLIS`, `SALV`, screen,
  toolbar, tree, color, icon, and demo data types) through an explicit resolver;
  never invent a shape when metadata is missing.
- [ ] Hoist report-local classes into collision-free generated helper classes,
  preserve inheritance and event-handler declarations, and map their private
  state without widening visibility.
- [ ] Fix generated method signatures and declaration placement responsible for
  `GGCONV-E204`, including event methods, table parameters, returning values,
  and references to local helper types.
- [ ] Lower static local `FORM` calls and event blocks with ordered control flow,
  including suspension and continuation at selection-screen, dynpro, popup,
  list, and transaction boundaries.
- [ ] Add typed compatibility adapters for the finite function-module families
  used by gg-gui: popup/dialog, classic ALV, dynamic selections, F4/help,
  variants, list navigation, frontend services, and capability probing.
- [ ] Split the broad `GGCONV-E501` category into actionable diagnostics for
  control construction, control methods, event registration, function-module
  adapters, frontend operations, dynamic type creation, and unsupported ABAP
  statements.
- [ ] Preserve text symbols and selection texts from report metadata so labels,
  tab captions, headings, and button text do not degrade to variable names.
- [ ] Emit runnable application content when only an optional feature is
  unsupported; reserve the whole-page diagnostic shell for failures that make
  safe entry impossible.
- [ ] Add converter fixtures based on minimal extracted constructs, not copies
  of the full gg-gui reports, for every new lowering and adapter rule.
- [ ] Require clean activation/transpilation of every generated class before
  its screenshot is classified as an application-parity candidate.

## Phase 2 - shared shell and visual language

- [ ] Add a compact classic theme for generated examples: pale blue work area,
  dark one-pixel borders, dense 22-28 px rows, restrained gradients, small
  system/monospace content fonts, and yellow input/action emphasis.
- [ ] Preserve the open-abap identity and accessible HTML semantics; reproduce
  recognizable layout behavior without copying SAP logos, proprietary icon
  bitmaps, operating-system title bars, or inaccessible image-only controls.
- [ ] Separate shell menus, the standard command toolbar, an application GUI
  status toolbar, and a control-local toolbar so each reference row appears in
  the correct hierarchy.
- [ ] Render title, status text, instruction text, message area, work area, and
  bottom action rows as distinct regions with consistent spacing across
  reports.
- [ ] Standardize focused, selected, changed, disabled, required, error,
  warning, total, subtotal, hotspot, and readonly states across selection,
  dynpro, list, tree, and grid controls.
- [ ] Match fixed-width ABAP field behavior: character fields left aligned;
  numeric, quantity, and amount fields right aligned; checkbox/radio controls
  compact; dates and times externally formatted without changing their values.
- [ ] Add keyboard parity for Enter, F1, F4, F8, Back, Exit, Cancel, toolbar
  commands, tab traversal, arrow navigation, and modal focus restoration.
- [ ] Keep responsive behavior usable below the reference width while making
  the fixed comparison viewport reproduce the reference grouping and density.

## Phase 3 - classic lists and selection screens

- [ ] **`ZGG_GUI_CATALOG`:** render the real catalog rows as a paged classic
  list with cyan headings, fixed-width category/program/title columns, program
  hotspots, page header/footer, vertical scroll, and drill-down behavior.
- [ ] **`ZGG_GUI_CLASSIC_LIST`:** preserve list colors, intensified and hotspot
  fragments, icon text, numeric alignment, top/end-of-page sections, and the
  Change/Top/Bottom/Reset application actions.
- [ ] **`ZGG_GUI_SEL_FIELDS`:** reproduce every typed field, label, default,
  password mask, checkbox, radio group, listbox, F4 affordance, required state,
  initial focus, validation, and external formatting.
- [ ] **`ZGG_GUI_SEL_RANGES`:** render low/high range pairs, include/exclude and
  option state, multiple-selection buttons, required markers, aligned typed
  values, and a working range editor dialog.
- [ ] **`ZGG_GUI_SEL_LAYOUT`:** honor block frames, block titles, comments,
  horizontal rules, explicit positions, function-key buttons, Reset, and About.
- [ ] **`ZGG_GUI_SEL_DYNAMIC`:** execute `AT SELECTION-SCREEN OUTPUT` changes for
  visibility, input, required, masked, listbox, checkbox, and radio-driven
  state, including Apply and contextual F1 help.
- [ ] **`ZGG_GUI_SEL_TABS`:** render Identity/Contact/Limits as real selection
  tabs, retain inactive-tab values server-side, validate only the proper
  callbacks, and restore focus when switching tabs.
- [ ] **`ZGG_GUI_MODAL_SELSCREEN`:** implement modal and fullscreen selection
  screen calls, explicit screen-number handling, validation/cancel return
  codes, parent value retention, and visible result status.
- [ ] **`ZGG_GUI_SEL_VARIANTS`:** implement variant read/save/delete/apply,
  report values, screen state, confirmations, ownership, and the six reference
  actions without trusting browser-supplied variant data.
- [ ] **`ZGG_GUI_SEL_FREE`:** implement the dynamic-selection dialog/fullscreen
  flow, selected-field criteria, returned ranges, reset, and the reference
  classic-list summary.

## Phase 4 - dynpro flow, status, navigation, and dialogs

- [ ] **`ZGG_GUI_DYNPRO_ELEMENTS`:** reproduce the paired Input/Output frames,
  typed controls, dropdown, checkbox/radios, value transport, Apply/Reset, and
  Back behavior with reference-like coordinates and widths.
- [ ] **`ZGG_GUI_DYNPRO_FLOW`:** run PBO/PAI in order, update the module log,
  preserve dynamic field/checkbox state, and implement Apply/Focus/Reset/
  Back/Cancel with correct cursor and message behavior.
- [ ] **`ZGG_GUI_TABLE_CONTROL`:** render the dense editable table, row
  selection, disabled cells, visible-row scrolling, current-line semantics,
  cell validation, and Append/Insert/Copy/Delete/Reset actions.
- [ ] **`ZGG_GUI_TABSTRIP`:** bind tabs to subscreens, retain each tab's state,
  support dynamic tab visibility and active tab, and update the status field
  and action row.
- [ ] **`ZGG_GUI_SUBSCREENS`:** after baseline identity is fixed, preserve parent
  and child field namespaces, PBO/PAI order, nested container geometry, state,
  and navigation shown by the intended reference screen.
- [ ] **`ZGG_GUI_DIALOGS_HELP`:** after baseline identity is fixed, implement F1,
  F4, modal screen positioning, nested dialog return values, cancellation, and
  parent focus restoration shown by the intended reference screen.
- [ ] **`ZGG_GUI_GUI_STATUS`:** support custom menu trees, application icon-bar
  actions, dynamic exclusions/disabled commands, title/status changes, context
  fields, PF keys, and forged-command rejection.
- [ ] **`ZGG_GUI_NAVIGATION`:** implement CALL SCREEN, SET/LEAVE SCREEN, list
  transitions, dialog suppression, SPA/GPA memory, SUBMIT, transaction calls,
  Reset/Leave/Back, and loop-safe continuations.
- [ ] **`ZGG_GUI_POPUPS`:** map the displayed popup function-module inventory to
  typed accessible dialogs, preserve the reference classic list and hotspots,
  and show returned values plus an ordered event log after each popup closes.

## Phase 5 - containers and composite layout

- [ ] **`ZGG_GUI_CFW_BASICS`:** render the text editor and control-local toolbar,
  register the event log, and implement focus, visibility, enablement,
  geometry, timer, refresh, reset, and Back operations through one control
  lifecycle.
- [ ] **`ZGG_GUI_CUSTOM_CONTAINER`:** attach the editor to the named dynpro
  custom-control area and expose parent, identity, visibility, geometry, and
  lifecycle diagnostics in the neighboring panel.
- [ ] **`ZGG_GUI_DOCKING_CONTAINER`:** render a resizable left dock and main
  diagnostic area, preserve extension/side/visibility state, and provide the
  reference action row.
- [ ] **`ZGG_GUI_SPLITTER_CONTAINER`:** support nested splitter/easy-splitter
  grids, draggable sashes, minimum sizes, retained ratios, editor panes, HTML
  viewer content, and reference status/actions.
- [ ] **`ZGG_GUI_DIALOG_CONTAINER`:** support a genuinely modeless dialog-box
  container over the parent dynpro, independent move/resize/close events, and
  continued access to the parent where the report permits it.
- [ ] **`ZGG_GUI_COMPOSITE`:** combine the tree, application toolbar, ALV grid,
  text editor, nested splitters, status fields, and bottom actions without
  flattening them into unrelated cards or losing cross-control selection.

## Phase 6 - individual controls and browser capability boundaries

- [ ] **`ZGG_GUI_PICTURE`:** match the initial URL/async selection screen, then
  load an allow-listed image with aspect/fit/alignment controls, alt text,
  loading/error state, and deterministic offline fixture behavior.
- [ ] **`ZGG_GUI_TEXTEDIT`:** match the large editor, local toolbar/status bar,
  readonly, word wrap, font, cursor/selection, stream/table round trips,
  protected lines, clear/restore, and capability-gated file load/save actions.
- [ ] **`ZGG_GUI_HTML_VIEWER`:** match the external-URL selection screen, then
  apply URL policy, sandbox content, load safe inline pages, report navigation
  state, and route `sapevent` links to typed host actions.
- [ ] **`ZGG_GUI_ABAP_BROWSER`:** render the ABAP browser document with its print
  toolbutton, status/instruction fields, navigation history, source changes,
  and all eight application actions.
- [ ] **`ZGG_GUI_TOOLBAR`:** support normal/toggle/menu/dropdown/disabled items,
  separators, item state changes, context menus, overflow, keyboard use, and
  event output while keeping the control toolbar distinct from shell actions.
- [ ] **`ZGG_GUI_CALENDAR`:** render the nine-month reference layout with week
  numbers, selected/focused date, marks, single/range modes, month navigation,
  bounds, Today/Set/Read/Mark/Clear/Recreate actions, and locale-stable labels.
- [ ] **`ZGG_GUI_DYNAMIC_DOCUMENT`:** render headings, formatted runs, icons,
  links, tables, form input/select/button controls, document metadata, event
  callbacks, background changes, refresh-in-place, and print behavior.
- [ ] **`ZGG_GUI_TIMER`:** implement a session-owned timer with start/stop,
  faster/slower interval changes, reusable instance semantics, completed-tick
  count, cancellation on navigation, and deterministic test-clock support.
- [ ] **`ZGG_GUI_FRONTEND_SERVICES`:** replace desktop assumptions with explicit
  browser upload/download, clipboard-permission, directory/registry capability
  messages, safe URL opening, sample-owned temporary data, cleanup, and an
  auditable log; never claim an operation the browser did not perform.
- [ ] **`ZGG_GUI_GRAPHICS`:** preserve the capability audit and status text,
  offer accessible chart/table fallbacks for bar/chart-engine/GFW requests,
  expose color selection through a web control, and label unavailable native
  implementations honestly.
- [ ] **`ZGG_GUI_ILI_DRAGDROP`:** preserve the reference's explicit legacy
  ActiveX-unavailable fallback, text area, geometry/visibility/menu action
  responses, and non-terminating Back path instead of simulating the native
  control.

## Phase 7 - trees and drag/drop

- [ ] **`ZGG_GUI_TREES`:** match column-tree hierarchy, headers, icons,
  checkbox/button/link/text/editable item classes, expand/collapse/lazy load,
  selection, double-click, context menu, column visibility, and mutation
  actions using opaque node keys.
- [ ] **`ZGG_GUI_TREE_MODELS`:** preserve the simple/list/column backend model
  distinctions, create the matching frontend views, retain expansion and
  selection, and make Compare show meaningful state rather than static text.
- [ ] **`ZGG_GUI_DRAG_DROP`:** render the tree/grid split view and implement
  keyboard-accessible move plus pointer drag/drop, flavor/effect validation,
  reject-next, undo, payload inspection, event status, and stable row/node IDs.

## Phase 8 - ALV and SALV

- [ ] **`ZGG_GUI_ALV_GRID`:** match the field catalog, toolbar, title, typed
  columns, group sorting, subtotals/totals, row colors, checkboxes, selection,
  scroll/state reads, criteria, variants, refresh/export, and presentation
  actions.
- [ ] **`ZGG_GUI_ALV_DYNAMIC`:** preserve runtime-created table and field-catalog
  metadata, generated style components, append-row and toggle-style behavior,
  typed totals, and dynamic structure description.
- [ ] **`ZGG_GUI_ALV_EDIT`:** support editable cells, checkboxes, dropdowns,
  cell buttons, hotspots, F4, changed-data protocol, validation, insert/copy/
  delete, and in-memory Save/Discard without implying database persistence.
- [ ] **`ZGG_GUI_ALV_FORMAT`:** render row/column/cell colors, styles, icons,
  traffic lights, symbols, grouped subtotals/totals, currency/quantity/unit/
  date/time formatting, and per-row Inspect actions.
- [ ] **`ZGG_GUI_ALV_EVENTS`:** dispatch custom toolbar/menu, delayed selection,
  print, data-change, drag/drop, application-event mode, hotspot/double-click,
  and explicit sample actions into the report's event log.
- [ ] **`ZGG_GUI_ALV_TREE`:** combine hierarchy and typed ALV columns, lazy
  children, node/item/context-menu events, calculation, mutation, expansion,
  selection, totals, and toolbar actions.
- [ ] **`ZGG_GUI_ALV_VARIANTS`:** implement variant info/apply/save/switch/
  delete/cleanup with a report-local handle, safe names, ownership, explicit
  confirmation, persisted layout state, and reference status/instructions.
- [ ] **`ZGG_GUI_ALV_CLASSIC`:** match the initial grid/list/hierarchical/block/
  popup/event selection screen and merge-field-catalog/variant controls, then
  route the selected classic ALV function-module mode to a semantic renderer.
- [ ] **`ZGG_GUI_SALV_TABLE`:** keep the current reference fallback until SALV
  factory support is real; once available, render selection, layouts, XML
  export, refresh, popup/fullscreen, and offline behavior without assertions or
  false success.
- [ ] **`ZGG_GUI_SALV_TREE`:** match hierarchy, per-cell item types, link and
  double-click events, add-leaf, selection, expand/collapse, and API comparison
  while fixing the clipped column content visible in the native reference.
- [ ] **`ZGG_GUI_SALV_HIERSEQ`:** render header/item relations, grouped blocks,
  quantities/prices/currency, total rows, classic ALV toolbar/navigation, and
  full-width scrolling without flattening parent and child records.

## Phase 9 - examples needed beyond the existing catalog

Examples `059`-`151` already cover the reusable status, selection, list,
dynpro, container, editor, picture, HTML, dynamic-document, toolbar, calendar,
ALV, tree, SALV, graphics, and composite foundations. Extend those examples and
their shared implementations for parity fixes. Add the following examples only
for contracts that the current catalog does not demonstrate.

- [ ] **152 - Timer lifecycle:** add `zcl_gg_ex_152` for deterministic ticks,
  start/stop, interval changes, instance reuse, navigation cancellation, and
  two-session isolation.
- [ ] **153 - Tree/grid drag and drop:** add `zcl_gg_ex_153` for typed flavors,
  move/copy effects, payload validation, reject, undo, keyboard parity, and
  stale/cross-session token rejection.
- [ ] **154 - Browser frontend services:** add `zcl_gg_ex_154` for explicit
  upload/download, clipboard permission, safe external navigation, capability
  reporting, cleanup, and refusal of desktop-only registry/directory claims.
- [ ] **155 - Modeless dialog container:** add `zcl_gg_ex_155` for independent
  move, resize, focus, parent interaction, close events, and cleanup; keep it
  distinct from example 121's modal dialog.
- [ ] **156 - Popup compatibility gallery:** add `zcl_gg_ex_156` for confirm,
  input, selection, table, message, progress, cancellation, focus restoration,
  and typed return values through the popup adapter family.
- [ ] **157 - ALV variant lifecycle:** add `zcl_gg_ex_157` for save/apply/switch/
  delete/cleanup, ownership, default layout, persistence failure, and safe
  report-local handles.
- [ ] **158 - Hierarchical-sequential SALV:** add `zcl_gg_ex_158` for typed
  header/item relations, grouped rendering, totals, sorting, selection, and
  semantic table fallback.
- [ ] **159 - Multi-month calendar:** add `zcl_gg_ex_159` for a nine-month grid,
  week numbers, marks, focus/selection distinction, range mode, navigation,
  locale, and deterministic current-date injection.
- [ ] Register examples `152`-`159` as transactions, add them to the catalog,
  and give each focused ABAP Unit and Playwright coverage without renumbering
  `059`-`151`.
- [ ] Update `GUI_HTML_CAPABILITIES.md` only after each new contract is
  implemented and verified; do not advertise planned behavior as available.

## Phase 10 - verification and rollout

- [ ] Add one smoke test per gg-gui report proving the first meaningful screen
  has report-specific content and no generic partial-conversion heading.
- [ ] Add interaction journeys for every visible reference action, including
  negative cases for forged function codes, row/node IDs, variants, paths,
  URLs, upload metadata, and disabled controls.
- [ ] Add focused visual baselines for the shared shell, selection screen,
  classic list, dynpro, table control, modal/modeless dialog, splitter, editor,
  toolbar, calendar, dynamic document, tree, ALV grid, ALV tree, SALV fallback,
  and graphics fallback.
- [ ] Use semantic masks only for documented volatile regions; do not mask the
  report work area, control geometry, labels, row data, state, or focus.
- [ ] Test narrow and reference-width layouts, mouse and keyboard operation,
  high zoom, forced colors, reduced motion, and screen-reader names/roles.
- [ ] Run converter unit tests, gg-gui conversion/capture, scaffold lint, ABAP
  transpilation/unit tests, HTML end-to-end tests, screenshot-diff tests, and
  `git diff --check` for every completed batch.
- [ ] Publish the gitignored comparison index locally with links to all 50
  generated/reference/diff triples and a machine-readable pass/fail summary.
- [ ] Accept a report only when its semantic, behavior, and visual gates pass;
  track partial progress by family rather than declaring parity because a page
  merely renders.

## Recommended delivery order

- [ ] **Batch A:** comparison tooling, deterministic fixtures, reference audit,
  report-owned dynpro metadata, declarations/DDIC, and local-class lowering.
- [ ] **Batch B:** shell theme plus catalog, classic-list, and all selection
  reports; these give the fastest visible proof that real content is running.
- [ ] **Batch C:** dynpro flow, table control, tabstrip/subscreens, status,
  navigation, dialogs, and popups.
- [ ] **Batch D:** container lifecycle, editors, HTML/picture, dynamic document,
  timer, calendar, toolbar, and the composite report.
- [ ] **Batch E:** trees, model adapters, and drag/drop.
- [ ] **Batch F:** ALV/SALV tables, formats, events, trees, variants, classic
  adapters, and intentional capability fallbacks.
- [ ] **Batch G:** full 50-report interaction run, normalized screenshot diffs,
  accessibility checks, documentation, and final parity audit.
