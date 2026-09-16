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

- [ ] No diagnostic or lifecycle payload string appears as visible page text in
  any of the 50 captures.
- [ ] Every control whose reference screenshot shows content renders content.
  No blank container where SAP has a grid, tree, document or HTML body.
- [ ] A gate fails when a container renders empty, when two program-owned text
  nodes overlap, or when a declared control is clipped by its host.
- [ ] Report titles come from the program, not the generated class name.
- [ ] `converter/test/gg-gui.mjs` records per-report rendering evidence that a
  human can read without opening 50 screenshots.
- [ ] Converter unit tests, gg-gui conversion/capture, scaffold lint, ABAP
  transpilation/unit tests, Playwright specs, and `git diff --check` pass for
  every batch.

## Phase 0 - make the visual gate able to fail

Same discipline as PLAN10 Phase 0. Until these can go red, every item below is
unverifiable.

- [ ] Add an **empty-container check**: a `CUST_CTRL` host whose rendered
  subtree contains no element with text, rows, or a media/form node fails,
  unless the report has a recorded capability boundary in
  `fallback-audit.json`.
  Baseline red set: `ALV_TREE`, `TREE_MODELS`, `ABAP_BROWSER`, `ALV_DYNAMIC`,
  and the HTML cell of `SPLITTER_CONTAINER`.
- [ ] Add an **overlap check**: two program-owned text-bearing nodes whose
  bounding boxes intersect by more than a small tolerance fails the report.
  Baseline red set includes `ALV_GRID`, `SALV_TABLE`, `SALV_TREE`,
  `SALV_HIERSEQ`, `TREES`, `CALENDAR`, `DYNAMIC_DOCUMENT`, `GRAPHICS`,
  `ILI_DRAGDROP`, `FRONTEND_SERVICES`, `DOCKING_CONTAINER`, `DIALOG_CONTAINER`.
- [ ] Add a **clipping check**: a control or table whose scrollHeight exceeds
  its clientHeight with no scrollable ancestor fails. Baseline red set:
  `CATALOG` (loses its last two rows, `SEL_LAYOUT` and `SEL_DYNAMIC`),
  `TABLE_CONTROL` (last row cut mid-height), `COMPOSITE` (detail pane over the
  grid), and every `CL_GUI_TEXTEDIT` host.
- [ ] Record the baseline red set as a known-failing list, as PLAN10 Phase 0
  did, so each batch measurably shrinks it.
- [ ] Keep the pixel diff as evidence only. It stays out of acceptance.

## Phase 1 - stop rendering diagnostics as content

This is the single highest-value change: it affects 28 of 50 reports and is one
expression.

- [ ] Stop emitting `is_snapshot-payload` as container text in
  `render_control_html` (`src/cl_gui_control.clas.abap:655` and `:657`). The
  payload is lifecycle diagnostics; move it to a `data-*` attribute, where the
  behavioural specs that assert on it can still read it.
- [ ] Audit every `set_payload` caller for strings that were only ever readable
  because of that leak, and decide per control whether the information belongs
  in `set_html` output, an attribute, or nowhere.
- [ ] Remove the leaked debug strings that reach the page the same way:
  `nodes=5; items=20; structure=MTREEITM`, `ALV border=1; rows=4`,
  `ALV rows: 5`, `Tree rows: N`, `Hierarchy column: ...`.
- [ ] Re-capture and confirm the overlap check from Phase 0 goes green for the
  reports whose only overlap was the payload line.

## Phase 2 - controls that render nothing

Each item is done when the control's content appears in the container and the
Phase 0 empty-container check passes for that report.

- [ ] **`CL_GUI_HTML_VIEWER` (`src/cl_gui_html_viewer.clas.abap`)** — emit the
  loaded document through `set_html` under the existing URL/sandbox policy.
  `load_data`, `show_url` and friends currently only `set_payload`. Affects
  `ZGG_GUI_ABAP_BROWSER`, the top-right cell of `ZGG_GUI_SPLITTER_CONTAINER`,
  and `ZGG_GUI_DYNAMIC_DOCUMENT`. SAP's `ABAP_BROWSER` reference shows a
  `CL_ABAP_BROWSER` heading and two paragraphs; the capture is blank.
- [ ] **`CL_ABAP_BROWSER` (`src/cl_abap_browser.clas.abap`)** — same fix, via
  the HTML viewer it wraps.
- [ ] **Tree models** — `cl_simple_tree_model`, `cl_list_tree_model` and
  `cl_column_tree_model` must render through their created control.
  `create_tree_control` is converted and called; the container stays blank.
  Affects `ZGG_GUI_TREE_MODELS`.
- [ ] **`CL_GUI_ALV_TREE`** — `cl_alv_tree_base` does call `set_html` at
  `src/tree/cl_alv_tree_base.clas.abap:701`, so trace why nothing reaches the
  page for `ZGG_GUI_ALV_TREE` despite a clean conversion. SAP shows 8 columns
  and 6 nodes (Product catalog / Input devices / Displays / Lazy-loaded
  products) plus its toolbar.
- [ ] **`ZGG_GUI_ALV_DYNAMIC`** — the only report with diagnostics (22 `E515`,
  1 `E516`). SAP shows 3 rows and a 16 / 737.90 total. Either lower the dynamic
  `ASSIGN COMPONENT` subset this report uses, or render the honest boundary text
  in the container instead of nothing, and record it in `fallback-audit.json`.
  A blank container is not an honest boundary.

## Phase 3 - controls that render, but wrong

- [ ] **TextEdit is clipped to ~2.5 lines** in all 24 reports that construct
  `CL_GUI_TEXTEDIT`, inside a full-height empty container, and never shows its
  toolbar or the `Li 1, Co 1 | Ln 1 - Ln 4 of 4 lines` status bar that the SAP
  reference shows in every case. `render_html` already ships
  `.gg-textedit-shell` CSS with `flex:1` and `height:auto!important`
  (`src/cl_gui_control.clas.abap:582`), so establish why the shell is not
  filling its host.
- [ ] **Tree hierarchy is lost.** `ZGG_GUI_TREES` renders every node at one
  indent level with a `v` marker on all of them — including leaf nodes and the
  *collapsed* Lazy children node. `ZGG_GUI_SALV_TREE`'s indentation is inverted:
  leaves render left of their parents. Emit real nesting, per-node expand state,
  and node icons.
- [ ] **Tree panes are ~90px wide** in `ZGG_GUI_DRAG_DROP` and
  `ZGG_GUI_COMPOSITE`, so every cell wraps to three lines. Honour the declared
  column widths.
- [ ] **`ZGG_GUI_ALV_FORMAT` shows none of what it demonstrates** — icons
  print as `@01@`/`@02@`, symbols as `+`/`-`, traffic lights as `1`/`2`/`3`, no
  row, column or cell colour appears. Resolve icon codes to the shipped icon
  assets and apply `LVC` colour/style to the rendered cells.
- [ ] **ALV subtotals are missing.** SAP's `ALV_GRID` renders per-category
  subtotal rows (Audio, Display, Input) above the grand total; the capture has
  only one Total row.
- [ ] **Decimal places are truncated on totals** — `752.4` and `971.4` where
  SAP shows `752.40` and `971.40` (`ALV_GRID`, `ALV_FORMAT`, `ALV_EVENTS`,
  `SALV_HIERSEQ`). Format totals with the column's declared decimals.
- [ ] **Calendar orientation is wrong.** SAP lays months out as columns
  (`2026/4` … `2027/1`) with `WN` week numbers and `MO`–`SU` rows; the
  capture stacks three months vertically as text, emits a stray `/`, and uses a
  native HTML date input. PLAN10 Phase 3 claimed a nine-month layout.
- [ ] **`ZGG_GUI_DYNAMIC_DOCUMENT` is unstyled** — serif default font,
  everything underlined as if it were a link, `ICON_DISPLAY` and `ICON_OKAY` as
  literal text, the 6-column table collapsed to 3, the right-hand Document
  area / User / Date block inline at the left, and none of the reference's blue
  and green table colours.
- [ ] **`ZGG_GUI_DIALOG_CONTAINER`** renders the modeless dialog as a clipped
  160x40 box overlapping two other text lines, not as a dialog window.
- [ ] **SALV exposes technical column names** — `GROUP_ID`, `GROUP_NAME`,
  `OWNER`, `ITEM_ID`, `QUANTITY` in `SALV_HIERSEQ`; `SALV_TABLE` additionally
  renders internal `EXCEPTION`, `TECHNICAL`, `CELL_COLORS`, `CELL_TYPES` and
  `LINK_HANDLES` columns that should never be visible.
- [ ] **`ZGG_GUI_TABSTRIP` puts its tabs below the subscreen** instead of above.
- [ ] **`ZGG_GUI_GUI_STATUS` stacks its menu bar vertically** — `Sample` over
  `Options` instead of side by side.
- [ ] **`ZGG_GUI_CLASSIC_LIST` renders its GUI status as a bottom row of raw
  uppercase function codes** (`BACK BOTTOM CANCEL CHANGE EXIT PRINT RESET TOP`).
  SAP shows a top application toolbar with icons and real labels — Change,
  Top, Bottom, Reset — and does not expose BACK/CANCEL/EXIT/PRINT there.
- [ ] **Group-box frames are an underscore run, and their titles are raw
  technical names**: `Input_elements`, `Output_and_status`,
  `Menu_Painter_behavior`, `Always_active`, `Variant_A`, `Container_hosts`,
  `Event_log`. Decode these the way PLAN10 Phase 2 decoded screen-painter text.
- [ ] **Empty output and status fields are dropped entirely**, so the layout
  below them shifts. `TABLE_CONTROL`, `TABSTRIP`, `TEXTEDIT` and `TOOLBAR` each
  lose a field the reference renders. An empty declared field is still a
  declared field.
- [ ] **SAP toolbars are absent or reduced**: the ALV standard toolbar of 15-20
  icon commands renders as 7 text buttons; TextEdit and tree toolbars are
  missing entirely.
- [ ] **List column tab stops are compressed** — in `ZGG_GUI_POPUPS` the
  Function module column lands at x≈280 against SAP's x≈400.

## Phase 4 - report titles

All 50 program XMLs carry a report title in `TPOOL` as `<ID>R</ID>`
(`ZGG_GUI_CATALOG` holds `SAP GUI Sample Catalog`). The 36 DYNPRO pages get
their titles right from screen metadata. The 14 LIST and SELECTION pages do not.

- [ ] Use the `TPOOL` `R` entry for LIST and SELECTION page headers. Today they
  render the generated class name: `ZCL_CV_CATALOG`, `ZCL_CV_POPUPS`,
  `ZCL_CV_CLASSIC_LIST`, `Selection: ZCL_CV_SEL_RANGES`.
- [ ] Render the classic list header line and page number that SAP shows above
  the list body.
- [ ] Do not let the harness's `description` option
  (`converter/test/gg-gui.mjs`) shadow a real program title.

## Phase 5 - correct the audits, again

- [ ] **`ZGG_GUI_SALV_TABLE`: the reference is now the degraded side.** The SAP
  capture shows a text fallback (`CL_SALV_TABLE is unavailable or nonfunctional
  in this runtime`); the generated page renders the real five-row table, which
  is what PLAN10 Phase 3 delivered. Decide explicitly whether the pinned
  reference should be re-captured or excluded from pixel acceptance, and record
  the decision. The generated page's own status text diverges from the
  reference's for the same reason.
- [ ] Re-check every `fallback-audit.json` entry against what now renders,
  as PLAN10 Phase 5 did for `SALV_TABLE`.
- [ ] Update `scaffold/GUI_HTML_CAPABILITIES.md` only after each control's
  contract is implemented and verified.

## Not defects - do not "fix"

- [ ] Confirm and document that fixed-length truncation is faithful. `Custom
  container created from explicit dynpro coordinat` and `SCREEN0 and
  DEFAULT_SCREEN are distinct or unb` are `gv_link_state TYPE c LENGTH 55` and
  `gv_relation TYPE c LENGTH 46` in the source report. SAP truncates the
  same way.
- [ ] The deterministic fixture date/time/user (`20250115`, `120000`,
  `GG_FIXTURE`) differing from the reference captures is intended.

## Phase 6 - verification and rollout

- [ ] Per batch: `npm run lint`, `npm run unit`, `npm --prefix converter run
  test:unit`, `npm --prefix converter run test:gg-gui`, `npm run
  test:html-browser`, and `git diff --check`.
- [ ] Keep the Phase 0 known-failing list current. Every batch removes entries;
  no batch adds one without a recorded reason.
- [ ] Publish per-report rendering evidence in the comparison index: container
  emptiness, overlap count, clipping, and title source, so the remaining work is
  visible without opening 50 images.
- [ ] Accept a report only when its controls hold real content and the
  strengthened Phase 0 checks pass. A page that merely renders is not parity —
  and after PLAN10, a page whose *logic runs* is not parity either.

## Recommended delivery order

- [ ] **Batch A:** Phase 0 in full. Ends with a red baseline that measures the
  real gap, as PLAN10 Batch A did.
- [ ] **Batch B:** Phase 1. One renderer change clears the most widespread
  defect across 28 reports; re-measure before doing anything report-specific.
- [ ] **Batch C:** Phase 2 blank containers — HTML viewer family first, since
  it unblocks three reports, then the tree family.
- [ ] **Batch D:** Phase 3 TextEdit and tree geometry, which together account
  for most of the remaining clipping and layout damage.
- [ ] **Batch E:** the rest of Phase 3 — ALV formatting, totals, decimals,
  calendar, dynamic document, toolbars, group boxes.
- [ ] **Batch F:** Phase 4 titles, Phase 5 audit correction, then the full
  50-report run and the final comparison.
