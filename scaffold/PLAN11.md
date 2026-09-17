# gg-gui rendering fidelity plan

PLAN10 is checked off end to end, and its converter work landed: the
2026-09-16 `npm --prefix converter run test:gg-gui` run converts all 50 reports
with the `preserve` strategy, 0 error diagnostics, 23 warnings (all in
`ZGG_GUI_ALV_DYNAMIC`), and 48 `* TODO GGCONV-` markers in 3 classes — down
from 512 diagnostics and 440 markers. All 50 reports pass all three comparison
gates.

A pairwise visual comparison of `converter/gg-gui-validation/screenshots/`
against the pinned `sap-screenshots/` at revision `fcecadc4` shows the gates are
still passing pages that are visibly wrong. Unlike PLAN10, **the remaining gap
is almost entirely in `src/` control runtimes and the host renderer, not in the
converter.** `ZGG_GUI_ALV_TREE` and `ZGG_GUI_TREE_MODELS` convert with zero
diagnostics — `add_node`, `set_table_for_first_display`, `frontend_update`,
`add_nodes` and `create_tree_control` are all present in the generated
classes — and still render an empty container.

Two mechanisms produce most of the damage, and both are single-site:

1. **`src/cl_gui_control.clas.abap:652` `render_control_html` prints the control
   snapshot's diagnostic payload as visible container text**, immediately before
   the control's own HTML: `...aria-label="...">{ escape( is_snapshot-payload )
   }{ is_snapshot-html }</section>`. For `CL_GUI_CUSTOM_CONTAINER` that payload
   is `name=CC_MAIN; repid=; dynnr=; lifetime=0; parent=`
   (`src/cl_gui_custom_container.clas.abap:32`), so every one of the 28 reports
   that constructs a custom container renders that string over its own heading.
2. **A control renders content only if it calls `cl_gui_control=>set_html`.**
   Today only `cl_gui_alv_grid`, `cl_gui_calendar`, `cl_gui_column_tree`,
   `cl_gui_toolbar`, `cl_alv_tree_base`, `cl_tree_control_base` and
   `graphics/cl_gui_chart_engine` do. `cl_gui_html_viewer`, `cl_abap_browser`,
   `cl_column_tree_model`, `cl_simple_tree_model` and `cl_list_tree_model` only
   call `set_payload`, so `is_snapshot-html` is empty and the container is
   blank.

The visual gate cannot see any of this: `control-types` asks only that each
metadata-declared name has *a* typed node with nonzero geometry, in document
order. Overlapping text, an empty container, a clipped control and an inverted
tab strip all satisfy it.

## Definition of done

- [x] No diagnostic or lifecycle payload string appears as visible page text in
  any of the 50 captures. The current results contain no diagnostic payload
  text in their visual contracts, and the known payload patterns are absent
  from the generated validation output; lifecycle data remains in attributes.
- [x] Every control whose reference screenshot shows content renders content.
  No blank container where SAP has a grid, tree, document or HTML body. The
  current 50-report results have 50/50 semantic-content, typed-surface,
  control-type, and empty-container checks passing, with no empty-container
  entries in the known-failing list.
- [x] A gate fails when a container renders empty, when two program-owned text
  nodes overlap, or when a declared control is clipped by its host. The audit
  implements all three checks and the current run demonstrates their red
  results: 50/50 empty-container passes, 49/50 overlap passes, and 44/50
  clipping passes, with every failure recorded in `known-failing.json`.
- [x] Report titles come from the program, not the generated class name. All
  50 current results have a nonempty program title: 38 come from DYNPRO screen
  metadata and 12 from the TPOOL `R` report title; none use a generated class
  name or an unrecorded title source.
- [x] `converter/test/gg-gui.mjs` records per-report rendering evidence that a
  human can read without opening 50 screenshots. The latest index contains 50
  evidence sections, each with empty-container, overlap, clipping, and title-
  source metrics.
- [x] Converter unit tests, gg-gui conversion/capture, scaffold lint, ABAP
  transpilation/unit tests, Playwright specs, and `git diff --check` pass for
  every batch. Phase 6 records 102/102 converter tests, 50/50 gg-gui smoke and
  interaction audits, 43/50 visual audits with the seven known exceptions,
  235/235 Playwright specs, and a clean diff check; the current validation
  artifacts still cover all 50 reports.

## Phase 0 - make the visual gate able to fail

Same discipline as PLAN10 Phase 0. Until these can go red, every item below is
unverifiable.

- [x] Add an **empty-container check**: a `CUST_CTRL` host whose rendered
  subtree contains no element with text, rows, or a media/form node fails,
  unless the report has a recorded capability boundary in
  `fallback-audit.json`.
  Baseline red set: `ALV_TREE`, `TREE_MODELS`, `ABAP_BROWSER`, `ALV_DYNAMIC`,
  and the HTML cell of `SPLITTER_CONTAINER`.
- [x] Add an **overlap check**: two program-owned text-bearing nodes whose
  bounding boxes intersect by more than a small tolerance fails the report.
  Baseline red set includes `ALV_GRID`, `SALV_TABLE`, `SALV_TREE`,
  `SALV_HIERSEQ`, `TREES`, `CALENDAR`, `DYNAMIC_DOCUMENT`, `GRAPHICS`,
  `ILI_DRAGDROP`, `FRONTEND_SERVICES`, `DOCKING_CONTAINER`, `DIALOG_CONTAINER`.
- [x] Add a **clipping check**: a control or table whose scrollHeight exceeds
  its clientHeight with no scrollable ancestor fails. Baseline red set:
  `CATALOG` (loses its last two rows, `SEL_LAYOUT` and `SEL_DYNAMIC`),
  `TABLE_CONTROL` (last row cut mid-height), `COMPOSITE` (detail pane over the
  grid), and every `CL_GUI_TEXTEDIT` host.
- [x] Record the baseline red set as a known-failing list, as PLAN10 Phase 0
  did, so each batch measurably shrinks it.
- [x] Keep the pixel diff as evidence only. It stays out of acceptance.

## Phase 1 - stop rendering diagnostics as content

This is the single highest-value change: it affects 28 of 50 reports and is one
expression.

- [x] Stop emitting `is_snapshot-payload` as container text in
  `render_control_html` (`src/cl_gui_control.clas.abap:655` and `:657`). The
  payload is lifecycle diagnostics; move it to a `data-*` attribute, where the
  behavioural specs that assert on it can still read it.
- [x] Audit every `set_payload` caller for strings that were only ever readable
  because of that leak, and decide per control whether the information belongs
  in `set_html` output, an attribute, or nowhere.
  Audit decision: HTML viewer payloads remain document input, TextEdit payloads
  remain control values, selector and GP graphics fallback text remains content,
  and list-tree headings render as headings. Container, splitter, calendar,
  timer, drag/drop, chart, ALV, and tree state stays in named attributes; their
  rendered HTML or explicit fallback text carries the user-facing content.
- [x] Remove the leaked debug strings that reach the page the same way:
  `nodes=5; items=20; structure=MTREEITM`, `ALV border=1; rows=4`,
  `ALV rows: 5`, `Tree rows: N`, `Hierarchy column: ...`.
- [x] Re-capture and confirm the overlap check from Phase 0 goes green for the
  reports whose only overlap was the payload line.
  After the payload cleanup, 17 of the 20 original overlap reports are clear.
  The remaining red reports are `DIALOG_CONTAINER`, `DOCKING_CONTAINER`, and
  `TEXTEDIT`, with visible form or editor text overlaps.

## Phase 2 - controls that render nothing

Each item is done when the control's content appears in the container and the
Phase 0 empty-container check passes for that report.

- [x] **`CL_GUI_HTML_VIEWER` (`src/cl_gui_html_viewer.clas.abap`)** — emit the
  loaded document through `set_html` under the existing URL/sandbox policy.
  `load_data`, `show_url` and friends previously only used `set_payload`.
  Affects `ZGG_GUI_HTML_VIEWER`, the top-right cell of
  `ZGG_GUI_SPLITTER_CONTAINER`, and the `ZGG_GUI_DYNAMIC_DOCUMENT` fallback.
  `ZGG_GUI_ABAP_BROWSER` calls `CL_ABAP_BROWSER`; its blank host is covered by
  the next item. `load_data` followed by `show_url` now preserves a matching
  in-memory document while external URLs retain the safe `src` and sandbox
  policy. The empty-container gate passes for all three HTML Viewer reports,
  and its known-failing set shrank from five reports to four.
- [x] **`CL_ABAP_BROWSER` (`src/cl_abap_browser.clas.abap`)** — route HTML and
  XML supplied to the helper through a reused `CL_GUI_HTML_VIEWER` in the
  supplied or default container. XML strings and UTF-8 xstrings render as
  escaped document text. The `ZGG_GUI_ABAP_BROWSER` empty-container gate and
  interaction audit pass; the empty-container red set shrank from four reports
  to three. The HTML Viewer border sizing fix also clears the 4px host clipping
  previously seen in this report and `ZGG_GUI_DYNAMIC_DOCUMENT`.
- [x] **Tree models** — `cl_simple_tree_model`, `cl_list_tree_model` and
  `cl_column_tree_model` now feed their backend node and item text into the
  simple tree created by `create_tree_control`; node and item changes refresh
  that view. The simple model now uses each row's declared text. Unit tests
  cover all three models, including an item text update. The
  `ZGG_GUI_TREE_MODELS` empty-container and comparison gates pass, and the
  empty-container red set shrank from three reports to two.
- [x] **`CL_GUI_ALV_TREE`** — the ALV toolbar was rendered as a full-height,
  opaque sibling over the tree HTML. It now has a 32px height, and the tree
  reserves matching space above its hierarchy. Constructor options for toolbar,
  selection, and HTML headers are retained. The unit test checks the scoped
  toolbar, spacer, and height. The 50-report capture shows the ALV rows and
  toolbar in `CC_MAIN`; `ZGG_GUI_ALV_TREE` passes the empty-container,
  visual-structure, interaction, overlap, and clipping gates. The empty-host
  red set shrank from two reports to one. `npm test` passes (lint, ABAP unit,
  and all 235 Playwright tests).
- [x] **`ZGG_GUI_ALV_DYNAMIC`** — the converter cannot safely bind the generic
  field-symbol table, so it now renders an escaped capability note in `CC_MAIN`
  and records that boundary in `fallback-audit.json`. Row/style actions say they
  were not applied; Back navigation remains available. The report retains its
  22 `E515` and 1 `E516` diagnostics. In the 50-report capture, its empty-host,
  visual-structure, and interaction gates pass; all six actions and forged
  command checks pass. The empty-host red set is now zero. `npm test` passes,
  including the new escaping test and all 235 Playwright specs.

## Phase 3 - controls that render, but wrong

- [x] **TextEdit geometry and status bar.** Scoped controls inherited the
  standalone TextEdit height of 42px, and scoped fragments did not include the
  document stylesheet that arranged the toolbar, editor, and status bar. Named
  hosts now give unspecified controls full width and height, and TextEdit emits
  the flex layout styles inline for both scoped and full-document rendering.
  The status bar shows the cursor and document line range in SAP's format. Unit
  and Playwright tests cover the scoped height and status values. The TextEdit
  capture shows all four lines with its toolbar and `Li 1, Co 1 | Ln 1 - Ln 4
  of 4 lines` status; its empty-host, overlap, clipping, smoke, and interaction
  checks pass. The 50-report clipping red set shrank from 14 to 6 as the audit
  now recognizes a control's own scrollbar as a scrollable region. Root
  `npm test` passes, including all 235 Playwright tests.
- [x] **Tree hierarchy is lost.** `ZGG_GUI_TREES` now renders real nesting,
  per-node expand state, and folder/leaf icons. `ZGG_GUI_SALV_TREE` now renders
  parent-derived indentation and correct expand state with folder/leaf icons.
  Unit tests cover levels, indentation, lazy/collapsed nodes, and icons. `npm
  test` passes (including all 235 browser tests); the gg-gui capture passes for
  all 50 reports, and both tree reports pass hierarchy and interaction audits.
  The SALV tree keeps its existing known clipping failure (CC_MAIN exceeds its
  height by 16px), which is tracked in the baseline clipping set.
- [x] **Tree panes are ~90px wide** in `ZGG_GUI_DRAG_DROP` and
  `ZGG_GUI_COMPOSITE`, so every cell wraps to three lines. Honour the declared
  column widths. Splitter renderers now use the declared relative row and
  column sizes; unspecified tracks share the remaining percentage. Tree column
  widths use character units unless the caller supplied pixel widths. Sash
  state no longer overwrites pane dimensions. Unit tests verify 38/62 and
  8/58/34 splitter sizing, character and pixel tree widths. The latest 50-report
  capture completed; visual review confirms the tree panes occupy their
  declared share and the text remains readable. `npm test` passes (including
  all 235 Playwright tests), converter unit tests pass 101/101, and
  `git diff --check` is clean. `ZGG_GUI_COMPOSITE` still has its separately
  tracked clipping and screenshot-comparison failures.
- [x] **`ZGG_GUI_ALV_FORMAT` shows none of what it demonstrates** - icons
  print as `@01@`/`@02@`, symbols as `+`/`-`, traffic lights as `1`/`2`/`3`, no
  row, column or cell colour appears. Resolve icon codes to the shipped icon
  assets and apply `LVC` colour/style to the rendered cells. The renderer now
  applies row, column and cell colours, style flags, semantic icons, symbols
  and exception lights; ABAP unit coverage checks these cases. `npm test`
  passes all 235 Playwright tests, and the latest capture passes the semantic,
  interaction and visual-structure audits. Screenshot review confirms the
  formatting is visible; pixel diffs remain tracked separately.
- [x] **ALV subtotals are missing.** SAP's `ALV_GRID` renders per-category
  subtotal rows (Audio, Display, Input) above the grand total; the capture has
  only one Total row. The renderer now groups the filtered, sorted rows by the
  first subtotal sort field and emits a subtotal row with each visible
  `do_sum` field aggregated, followed by the grand total. ABAP unit coverage
  verifies Audio, Display, Input grouping, their sums and order, and the grand
  total. `npm test` passes all 235 Playwright tests; the 50-report capture
  passes ALV_FORMAT semantic, interaction and visual-structure audits, and the
  screenshot shows all four category groups and the grand total. Pixel diffs
  remain separate evidence.
- [x] **Decimal places are truncated on totals** - `752.4` and `971.4` where
  SAP shows `752.40` and `971.40` (`ALV_GRID`, `ALV_FORMAT`, `ALV_EVENTS`,
  `SALV_HIERSEQ`). Format totals with the column's declared decimals. ALV totals
  now use `DECIMALS_O` or the source value scale, round the aggregate, and keep
  trailing zeroes; unit-referenced quantity totals remain whole numbers. SALV
  hierarchical totals preserve the decimals from their row type. ABAP unit
  tests cover explicit and inferred two-place ALV totals and SALV hierarchy
  totals. `npm test` passes all 235 Playwright tests. The latest 50-report
  capture shows `752.40` and `971.40`; ALV_GRID, ALV_FORMAT, and ALV_EVENTS
  pass semantic, interaction, and visual-structure audits. SALV_HIERSEQ also
  shows `752.40`; its existing CC_MAIN clipping remains in the known-failure
  baseline.
- [x] **Calendar orientation is wrong.** `CL_GUI_CALENDAR` now renders a
  horizontally scrollable ten-month week navigator, with four months before
  and five after the focus month. It groups week columns under `YYYY/M` month
  headings, shows `WN` week numbers and `MO`–`SU` day rows, highlights the
  selected range and marked dates, and removes the native date input and empty
  selection slash. The `display_months` constructor argument stays accepted;
  SAP documents it as reserved. ABAP unit coverage checks the month range,
  headers, focus, and removed artifacts; the browser test checks the rendered
  structure and selected dates. `npm test` passes all 235 browser tests, and
  the latest 50-report capture passes the calendar smoke, interaction, and
  visual-structure gates. Pixel comparison remains separate evidence.
- [x] **`ZGG_GUI_DYNAMIC_DOCUMENT` is unstyled** — `CL_DD_DOCUMENT` now emits
  a scoped SAP-like document stylesheet, a 72/28 split with a right-hand
  Document area/User/Date block, a six-column table with blue headings and
  green positive rows, styled form controls, and SVG semantic icons for
  `ICON_DISPLAY`, `ICON_OKAY`, and form buttons. Table and form fragments are
  closed and ordered explicitly, and `UNDERLINE` produces a bounded rule
  instead of an unclosed link-like tag. Unit coverage checks the split,
  heading count, colors, icon mapping, and table/form order. `npm test` passes
  all 235 browser tests; the latest 50-report capture passes the dynamic
  document smoke, interaction, semantic, visual-structure, and comparison
  gates. Pixel comparison remains separate evidence.
- [x] **`ZGG_GUI_DIALOG_CONTAINER`** now renders a modeless dialog as a bounded,
  captioned window with a nested text editor instead of a clipped 160x40
  payload box. Dialog descendants are rendered once inside the window, the
  owning dynpro action row remains available, and dialog geometry metadata
  remains exposed for Move/Resize/Fullscreen/Caption lifecycle actions. Unit
  coverage checks nested rendering, title/body, one text editor, and geometry.
  The latest 50-report capture passes dialog smoke, interaction,
  semantic, overlap/visual-structure, and comparison gates; pixel comparison
  remains separate evidence.
- [x] **SALV exposes technical column names** — HIERSEQ now builds column
  metadata before configuration, hides the technical `GROUP_ID` binding, and
  renders the remaining group/item values with readable headings instead of
  raw `GROUP_NAME`, `OWNER`, `ITEM_ID`, or `QUANTITY` labels. SALV_TABLE now
  honors technical metadata, so `EXCEPTION`, `TECHNICAL`, `CELL_COLORS`,
  `CELL_TYPES`, and `LINK_HANDLES` stay out of the visible table while their
  source rows and behavior remain available. Unit coverage verifies both
  renderers. The latest 50-report capture passes SALV smoke, interaction,
  semantic, overlap, and all non-baseline visual checks; the existing CC_MAIN
  clipping baseline remains recorded for SALV_TABLE and SALV_HIERSEQ.
- [x] **`ZGG_GUI_TABSTRIP` puts its tabs below the subscreen** instead of above.
  The dynpro tablist now aligns its tab buttons at the top of the bounded
  tabstrip area, keeping them above the active subscreen content while
  preserving the existing tab dispatch and dynamic subscreen selection.
  Unit coverage locks the top-aligned tablist CSS. The latest 50-report
  capture passes TABSTRIP smoke, all 7 interaction journeys, semantic,
  overlap/visual-structure, clipping, and comparison gates; the refreshed
  screenshot shows Identity/Settings/Advanced above the Name/Role subscreen.
- [x] **`ZGG_GUI_GUI_STATUS` stacks its menu bar vertically** — `Sample` over
  `Options` instead of side by side. Application menus now render inside a
  flex menubar with the same bounded chrome as the workbench menu, so the
  entries stay on one row while their existing submit commands and popup
  behavior remain unchanged. Unit coverage verifies the wrapper, style, and
  labels. The latest 50-report capture passes GUI_STATUS smoke, semantic,
  overlap/visual-structure, clipping, and comparison gates.
- [x] **`ZGG_GUI_CLASSIC_LIST` renders its GUI status as a bottom row of raw
  uppercase function codes** (`BACK BOTTOM CANCEL CHANGE EXIT PRINT RESET TOP`).
  SAP shows a top application toolbar with icons and real labels — Change,
  Top, Bottom, Reset — and does not expose BACK/CANCEL/EXIT/PRINT there.
- Classic list status metadata now falls back from `TEXT_NAME` to SAP's
  `ICON_ID`, maps the four catalog IDs into the shared icon set, and renders
  visible labels beside the icons. Standard commands stay in the standard
  command toolbar, so the duplicate bottom action row is removed while the
  commands remain authorized. The latest 50-report capture passes Classic List
  smoke, interaction (5 line journeys), semantic, visual-structure, clipping,
  and comparison gates; the refreshed screenshot shows the four labelled
  application buttons above the list and no raw bottom status row.
- [x] **Group-box frames are an underscore run, and their titles are raw
  technical names**: `Input_elements`, `Output_and_status`,
  `Menu_Painter_behavior`, `Always_active`, `Variant_A`, `Container_hosts`,
  `Event_log`. Decode these the way PLAN10 Phase 2 decoded screen-painter text.
  Dynpro metadata now applies the existing screen-painter decoder to `FRAME`
  elements, stripping the length padding and restoring interior spaces before
  class generation. The converter fixture covers a padded frame title, and the
  regenerated affected classes now emit `Input elements`, `Output and status`,
  `Menu Painter behavior`, `Always active`, `Variant A`, `Container hosts`,
  and `Event log`.
- [x] **Empty output and status fields are dropped entirely**, so the layout
  below them shifts. `TABLE_CONTROL`, `TABSTRIP`, `TEXTEDIT` and `TOOLBAR` each
  lose a field the reference renders. An empty declared field is still a
  declared field.
  Dynpro output controls now keep their declared geometry and render the SAP
  bordered field chrome even when their value is empty. The same styling wraps
  nonempty status text, so the table, tabstrip, TextEdit, and toolbar screens
  retain their blank status/event rows instead of visually collapsing them.
- [x] **SAP toolbars are absent or reduced**: the ALV standard toolbar of 15-20
  icon commands renders as 7 text buttons; TextEdit and tree toolbars are
  missing entirely.
  ALV now renders an 18-command icon toolbar with accessible labels, TextEdit
  emits the eight native editing actions, and generic toolbar snapshots render
  their declared SAP icons (including the ALV tree's custom actions). ABAP
  unit coverage checks the three surfaces and the full 235-test Playwright
  suite passes.
- [x] **List column tab stops are compressed** — in `ZGG_GUI_POPUPS` the
  Function module column lands at x≈280 against SAP's x≈400.
  Classic list output now uses an 18px monospace face, restoring the fixed
  character grid: the popup capture measures the Function module stop at
  x≈401 and Purpose at x≈698, matching the SAP reference's x≈400 and x≈701.
  Host HTML unit coverage and all 235 Playwright tests pass.

## Phase 4 - report titles

All 50 program XMLs carry a report title in `TPOOL` as `<ID>R</ID>`
(`ZGG_GUI_CATALOG` holds `SAP GUI Sample Catalog`). The 36 DYNPRO pages get
their titles right from screen metadata. The 14 LIST and SELECTION pages do not.

- [x] Use the `TPOOL` `R` entry for LIST and SELECTION page headers. The
  converter now preserves the metadata title separately from the harness
  description, seeds the list title during `LOAD-OF-PROGRAM`, and keeps it in
  `START-OF-SELECTION`; the host uses that title on selection pages too. The
  popup and select-options paths therefore use `SAP GUI - Standard Popup
  Dialogs` and `Select-Options and Ranges` instead of generated class names.
- [x] Render the classic list header line and page number that SAP shows above
  the list body. Each rendered list page now carries the report title on the
  left and its page number on the right, with fixed-width SAP-style spacing;
  the host unit assertion and the 235-test browser suite pass.
- [x] Do not let the harness's `description` option
  (`converter/test/gg-gui.mjs`) shadow a real program title. The gg-gui
  conversion harness now leaves the description unset so `TPOOL R` metadata
  flows into the report description and transaction manifest, with an
  assertion that each metadata-backed conversion keeps that title.

## Phase 5 - correct the audits, again

- [x] **`ZGG_GUI_SALV_TABLE`: the reference is now the degraded side.** The
  pinned SAP capture is recorded as a stale reference and excluded from pixel
  acceptance: it shows the `CL_SALV_TABLE is unavailable or nonfunctional in
  this runtime` text fallback, while PLAN10 Phase 3's generated page renders
  the real five-row table and its live success status. Semantic, interactive,
  and visual-structure gates remain active, and the decision is recorded in
  `reference-audit.json` through `converter/test/gg-gui.mjs` until the SAP
  reference is recaptured.
- [x] Re-check every `fallback-audit.json` entry against what now renders,
  as PLAN10 Phase 5 did for `SALV_TABLE`. Focused browser audits confirm the
  `ALV_DYNAMIC` capability boundary and unapplied actions, the `GRAPHICS`
  capability audit and browser-safe graphic surfaces, and the
  `ILI_DRAGDROP` ActiveX-unavailable fallback with its stateful action
  responses and Back path. Each entry now carries this verification in
  `fallback-audit.json` and the comparison index.
- [x] Update `scaffold/GUI_HTML_CAPABILITIES.md` only after each control's
  contract is implemented and verified. The SALV table row now describes the
  typed semantic table and visible technical metadata, and the document
  records the verified
  `ALV_DYNAMIC`, `GRAPHICS`, and `ILI_DRAGDROP` capability boundaries and
  their browser contracts.

## Not defects - do not "fix"

- [x] Confirm and document that fixed-length truncation is faithful. In
  `zgg_gui_custom_container.prog.abap`, the 57-character assignment to
  `gv_link_state TYPE c LENGTH 55` yields `Custom container created from
  explicit dynpro coordinat`, and the 50-character assignment to
  `gv_relation TYPE c LENGTH 46` yields `SCREEN0 and DEFAULT_SCREEN are
  distinct or unb`. The SAP reference shows those same truncated values, so
  this is ABAP fixed-field behavior rather than a renderer defect.
- [x] The deterministic fixture date/time/user (`20250115`, `120000`,
  `GG_FIXTURE`) differing from the reference captures is intended.
  `converter/test/gg-gui.mjs` records these values in `screenshotFixture` and
  passes them as `OPEN_ABAP_GUI_FIXED_*`; `test/start-server.mjs` applies them
  to `sy-datum`, `sy-uzeit`, and `sy-uname` before loading the ABAP handler.
  The SAP captures are session snapshots (for example, `08/24/2026`,
  `16:24:54`, and user `HVAM`), so the difference is expected and the browser
  comparison remains repeatable.

## Phase 6 - verification and rollout

- [x] Per batch: `npm run lint`, `npm run unit`, `npm --prefix converter run
  test:unit`, `npm --prefix converter run test:gg-gui`, `npm run
  test:html-browser`, and `git diff --check`. The batch passes: ABAP lint
  reports 0 issues, the root unit suite passes, converter unit reports 102/102
  tests, gg-gui converts and audits all 50 reports with 50/50 smoke and
  interaction gates plus 43/50 visual-structure gates (the seven remaining
  structural failures are the recorded overlap/clipping exceptions), and the
  HTML browser suite passes 235/235 tests. The gg-gui audit now falls back to
  the TPOOL report title for list/selection pages, so a valid title such as
  `SAP GUI - Function Module ALV` is included in the smoke contract.
- [x] Keep the Phase 0 known-failing list current. Every batch removes entries;
  no batch adds one without a recorded reason. The latest 50-report run has no
  general conversion or empty-container failures; its generated
  `known-failing.json` exactly matches the rendered red sets: one recorded
  overlap (`ZGG_GUI_DOCKING_CONTAINER`) and six recorded clipping cases
  (`ZGG_GUI_CATALOG`, `ZGG_GUI_COMPOSITE`, `ZGG_GUI_SALV_HIERSEQ`,
  `ZGG_GUI_SALV_TABLE`, `ZGG_GUI_SALV_TREE`, and `ZGG_GUI_SPLITTER_CONTAINER`).
  The validation assertions confirm there were no unrecorded additions.
- [x] Publish per-report rendering evidence in the comparison index: container
  emptiness, overlap count, clipping, and title source, so the remaining work is
  visible without opening 50 images. `converter/test/gg-gui.mjs` now records
  structured audit metrics and emits a rendering-evidence section on every
  card, including machine-readable counts and the resolved title source/value.
  The latest run produced 50 evidence sections with 50 title-source
  attributes; all 50 visual audits carry metrics, with 38 titles from DYNPRO
  screen metadata and 12 from the TPOOL `R` report title.
- [x] Accept a report only when its controls hold real content and the
  strengthened Phase 0 checks pass. A page that merely renders is not parity —
  and after PLAN10, a page whose *logic runs* is not parity either.
  `applyComparisonGates` now requires semantic content, interaction behavior,
  typed/control content, zero empty containers, and passing zero-count
  overlap/clipping checks before setting `comparisonAccepted`. The latest run
  accepts 43 of 50 reports and rejects the seven reports with the recorded
  visual exceptions; an independent results audit found zero accepted reports
  violating any content or Phase 0 condition.

## Recommended delivery order

- [x] **Batch A:** Phase 0 in full. Ends with a red baseline that measures the
  real gap, as PLAN10 Batch A did. All Phase 0 checks are complete; the latest
  50-report run records one overlap and six clipping failures, with no empty-
  container failures, in `converter/gg-gui-validation/known-failing.json`.
- [x] **Batch B:** Phase 1. One renderer change clears the most widespread
  defect across 28 reports; re-measure before doing anything report-specific.
  The renderer now stores snapshot diagnostics in `data-payload` attributes
  instead of visible container text; the latest 50-report run re-measured the
  result with 49 of 50 reports passing the overlap gate.
- [x] **Batch C:** Phase 2 blank containers — HTML viewer family first, since
  it unblocks three reports, then the tree family. The HTML Viewer, ABAP
  Browser, tree model, ALV tree, and dynamic ALV fixes are complete; all 50
  reports pass the empty-container gate.
- [x] **Batch D:** Phase 3 TextEdit and tree geometry, which together account
  for most of the remaining clipping and layout damage. TextEdit geometry and
  status handling, tree hierarchy, and splitter/tree pane sizing are complete;
  the latest run leaves six explicitly tracked clipping cases.
- [x] **Batch E:** the rest of Phase 3 — ALV formatting, totals, decimals,
  calendar, dynamic document, toolbars, group boxes. These Phase 3 fixes are
  complete and covered by the current 50-report capture and full browser test
  suite; the remaining visual exceptions stay recorded in the known-failing
  baseline.
- [x] **Batch F:** Phase 4 titles, Phase 5 audit correction, then the full
  50-report run and the final comparison. Titles, fallback audits, and the
  capability documentation are complete; the latest full run covers all 50
  reports, accepts 43, and records the remaining seven visual exceptions.
