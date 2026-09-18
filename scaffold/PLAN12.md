# gg-gui native-reference parity closure plan

PLAN11 made the converted gg-gui applications functional and removed the most
obvious empty controls, payload leaks, and hierarchy failures. The current
validation run is materially better than the PLAN10 baseline, but the real SAP
screenshots still show that "comparison accepted" is not the same as visual or
content parity.

This plan is based on the 50 native references in
`converter/gg-gui-validation/repository/sap-screenshots/`, not the
`zgg_ex_*` preview screenshots. The pinned gg-gui revision is
`fcecadc4f6d67debf8828c2f6dd11eb0027a58b8`.

## Current measured baseline

| Measure | Current result |
| --- | ---: |
| Native/browser screenshot pairs | 50 |
| Pixel-identical pairs | 0 |
| Changed-pixel range | 42.97% - 95.06% |
| Median changed pixels | 71.51% |
| Reports accepted by all current comparison gates | 43/50 |
| Recorded structural failures | 7 reports |
| Generated `TODO GGCONV-*` markers | 33 in 3 classes |
| Confirmed stale native references | 3 |

The largest accepted deltas are selection and launcher-style pages:
`HTML_VIEWER` 95.06%, `PICTURE` 95.05%, `MODAL_SELSCREEN` 94.98%,
`SEL_FREE` 94.90%, `POPUPS` 94.62%, `SEL_VARIANTS` 93.77%, and
`ALV_CLASSIC` 93.62%. These pages pass because the present gates find the
expected text and controls, even when content geometry, action placement,
field styling, and density do not match the native reference. The full-frame
percentages are also inflated by the intentionally different browser chrome,
which Phase 1 removes from native-content scoring without changing it.

Three converter omissions are also visible in generated output:

1. `ZGG_GUI_ALV_DYNAMIC` contains 30 `GGCONV-E515` omissions and one
   `GGCONV-E501` fallback. Its native runtime-created ALV table is replaced by
   a capability-boundary message, so rows, totals, editable state, and style
   actions are absent.
2. `ZGG_GUI_HTML_VIEWER` drops the generated
   `<p><strong>Detected:</strong> ...</p>` line because HTML tags inside an
   ABAP string template are misclassified as field symbols.
3. `ZGG_GUI_TABLE_CONTROL` omits dynamic `SET CURSOR`, so row/field cursor
   restoration is not reproduced.

The remaining structural red set is one overlap in
`ZGG_GUI_DOCKING_CONTAINER` and clipping in `ZGG_GUI_CATALOG`,
`ZGG_GUI_COMPOSITE`, `ZGG_GUI_SALV_HIERSEQ`, `ZGG_GUI_SALV_TABLE`,
`ZGG_GUI_SALV_TREE`, and `ZGG_GUI_SPLITTER_CONTAINER`.

## Scope constraint - transaction content only

The global open-abap browser chrome is frozen. PLAN12 must not restyle,
reposition, resize, or replace the application header, menus, command field,
global navigation toolbar, or global footer/status bar. Native SAP chrome is
not a target for this plan.

All rendering changes are scoped below the transaction content root. Local
application toolbars, ALV/tree/TextEdit toolbars, dynpro fields, lists,
containers, dialogs, and report-owned status/detail fields are content and are
in scope. The comparison pipeline must crop or anchor to that content region so
unrelated browser-chrome pixels neither cause failures nor motivate chrome
changes.

## Definition of done

- [ ] All 50 native references have verified provenance, the intended initial
  application state, dimensions, and SHA-256 recorded in a manifest. A launcher
  screen or stale capability fallback cannot silently stand in for the report.
- [ ] The three confirmed stale references (`SALV_TABLE`, `SUBSCREENS`, and
  `DIALOGS_HELP`) are recaptured in SAP GUI or remain explicitly blocked from
  parity acceptance with an owner and expiry condition.
- [ ] No `TODO GGCONV-*` marker remains in any generated gg-gui validation
  class. `ZGG_GUI_ALV_DYNAMIC` renders its real runtime-created table and all
  of its row/style actions instead of a capability boundary.
- [ ] All 50 reports pass empty-container, overlap, and clipping checks. The
  current seven-report visual exception list is empty.
- [ ] Comparison acceptance includes normalized application-region fidelity,
  control geometry, visible row/column cardinality, toolbar/action placement,
  and report-specific visual states. Finding expected text is not sufficient.
- [ ] No accepted report exceeds its reviewed visual-delta budget. Budgets are
  established only after transaction-content normalization and are ratcheted
  down; they are never automatically widened to make a regression pass.
- [ ] The global browser chrome has identical markup, computed geometry, and
  visible styling before and after PLAN12. A dedicated invariance check fails
  if content work changes it.
- [ ] Reports whose purpose appears only after an action have native/browser
  comparison checkpoints for those states, not only one initial screenshot.
- [ ] Native and browser reports agree on visible content: headings, fields,
  values, rows, columns, totals, tree hierarchy, selection/current state,
  toolbars, status/detail lines, and explicit capability boundaries.
- [ ] Accessibility remains intact while fidelity improves: labels, roles,
  keyboard operation, focus order, high-contrast focus, and reduced-motion
  behavior continue to pass.
- [ ] Root tests, converter tests, the 50-report gg-gui run, browser tests, and
  `git diff --check` pass at every delivery batch.

## Phase 0 - make the references authoritative

- [ ] Add a checked-in native-reference manifest generated from the pinned
  gg-gui checkout. Record program name, source file, screenshot filename,
  expected first screen, dimensions, SHA-256, and reference status.
- [ ] Validate every native image against the intended report state. Fail the
  run if a screenshot is a launcher (`SAP GUI Program Execution`), belongs to
  another report, is missing, or changed without a revision/manifest update.
- [ ] Recapture `ZGG_GUI_SUBSCREENS` and `ZGG_GUI_DIALOGS_HELP`; their current
  references show the program launcher rather than dynpro 0100.
- [ ] Recapture `ZGG_GUI_SALV_TABLE` with a runtime where `CL_SALV_TABLE` is
  functional. Until then, retain its semantic and interaction gates but do not
  describe its current native image as visual parity evidence.
- [ ] Publish reference provenance on every comparison card, including the
  gg-gui revision and reference SHA, so a reviewer can distinguish native SAP
  evidence from preview-deployment browser screenshots.

## Phase 1 - make visual acceptance meaningful

- [ ] Detect and crop to the transaction content root in both native and
  browser captures. Exclude the global browser header, menus, command field,
  navigation toolbar, and footer from native-content scoring and diff images.
- [ ] Add a separate browser-chrome invariance gate that compares the browser
  shell only against its pre-PLAN12 browser baseline. It must not compare the
  browser shell to SAP GUI chrome or permit shell changes for visual parity.
- [ ] Add anchor geometry checks for titles, group boxes, fields, custom-control
  hosts, toolbars, tables, trees, and action rows. Record native and browser
  bounding boxes and fail on position/size drift beyond a small reviewed
  tolerance.
- [ ] Add visible-content cardinality checks: field count, toolbar command
  count, table row/column count, tree node/column count, subtotal/total count,
  and status/detail line count.
- [ ] Add visual-state checks for editable/read-only/disabled fields, current
  cell, selected row, expanded/collapsed node, active tab, checkbox/radio state,
  totals, errors, and capability-boundary surfaces.
- [ ] Add a perceptual application-region score that discounts only small font
  antialiasing differences. Do not mask geometry, missing content, colors,
  borders, icons, or whole controls.
- [ ] Replace the current pass condition that accepts 43 reports with large
  deltas. A report passes only when semantic, interaction, structure, and its
  reviewed visual budget all pass.
- [ ] Store the measured baseline in `results.json` and display category-level
  regressions in the comparison index; do not require reviewers to inspect 50
  pink full-frame images to find one missing control.

## Phase 2 - close the remaining converter omissions

- [ ] Fix field-symbol detection inside ABAP string templates so literal HTML
  tags such as `<p>` and `<strong>` are not parsed as field symbols. Restore the
  omitted frontend/version paragraph in `ZGG_GUI_HTML_VIEWER` and add converter
  unit coverage with multiple tags and embedded expressions.
- [ ] Lower dynamic `SET CURSOR FIELD ... LINE ...` into the host dialog cursor
  model. Verify `ZGG_GUI_TABLE_CONTROL` restores both the field and visible row
  after append, insert, delete, scroll, reset, and round-trip actions.
- [ ] Support the finite generic-table pattern used by
  `ZGG_GUI_ALV_DYNAMIC`: `ASSIGN ref->*`, generic standard-table field symbols,
  `APPEND INITIAL LINE ... ASSIGNING`, and `ASSIGN COMPONENT` on a runtime row.
- [ ] Preserve the dynamic row schema produced by
  `CL_ALV_TABLE_CREATE=>CREATE_DYNAMIC_TABLE`, including the generated style
  component, field catalog, decimals, checkbox/edit metadata, and totals.
- [ ] Lower `FREE`/unassignment for the supported dynamic reference and table
  pattern without inventing unsafe aliases.
- [ ] Remove the `ALV_DYNAMIC` capability fallback. Render D100-D300 initially,
  then verify append, toggle style, describe, refresh, and reset produce the
  same visible table/state transitions as the source report.
- [ ] Require zero generated TODO markers and zero converter diagnostics for
  all 50 reports before this phase closes.

## Phase 3 - shared content surface and selection-screen fidelity

- [ ] Keep the host shell untouched and make only the transaction content
  rectangle deterministic at the 1299x1009 validation viewport. Align the
  report-owned content origin, padding, width, and height below the existing
  browser chrome.
- [ ] Centralize SAP-like visual tokens for typography, row height, border
  color, editable yellow, output/read-only blue-grey, selected/current state,
  group-box fill, button height, icon size, and disabled contrast.
- [ ] Render selection-screen actions in a report-owned local toolbar inside
  the transaction content surface. Do not add them to or modify the global
  browser toolbar. Remove duplicated generic bottom `Execute` and `Cancel`
  rows while preserving keyboard shortcuts and explicit Back paths.
- [ ] Honor source field positions and output lengths for parameters,
  checkboxes, radio groups, list boxes, select-options, range buttons, variant
  controls, and comments instead of allowing fluid form layout to reshape the
  screen.
- [ ] Match selection tabs and framed blocks in `SEL_TABS`, `SEL_DYNAMIC`,
  `SEL_LAYOUT`, `SEL_FIELDS`, `SEL_RANGES`, `SEL_VARIANTS`, `SEL_FREE`, and
  `MODAL_SELSCREEN`, including active-tab geometry and dynamic visibility.
- [ ] Add focused screenshot assertions for every selection-screen family so
  shared content-layout changes cannot make eight reports regress together.

## Phase 4 - list, dynpro, and table-control fidelity

- [ ] Fix `ZGG_GUI_CATALOG` by giving the list output a bounded vertical scroll
  region; all catalog rows, including the final selection examples, must be
  reachable without extending 370px below the captured work area.
- [ ] Match native list character metrics, line rules, header/page-number
  placement, horizontal scrolling, hotspot/current-line state, and highlighted
  cells in `CATALOG`, `POPUPS`, and `CLASSIC_LIST`.
- [ ] Preserve exact dynpro field geometry, empty output fields, input/output
  color, group-box bounds, and action placement in `DYNPRO_ELEMENTS`,
  `DYNPRO_FLOW`, `GUI_STATUS`, `NAVIGATION`, `TABSTRIP`, and `SUBSCREENS`.
- [ ] Render the table control's configured visible-row count rather than a
  large generic grid of blank rows. Match row selectors, top line, vertical and
  horizontal scrollbars, per-row input state, and current cell.
- [ ] Complete cursor restoration from Phase 2 and add visual checkpoints after
  scroll/insert/delete so the table-control screenshot proves the cursor and
  top-line state, not only the data mutation.

## Phase 5 - ALV, SALV, and tree fidelity

- [ ] Match ALV toolbar command order, icon size, separators, disabled state,
  and overflow behavior. The current tiny generic toolbar is not equivalent to
  the native grid toolbar even when every command exists in the DOM.
- [ ] Match field-catalog-driven column widths, header text, numeric alignment,
  row density, zebra/current/selected state, edit widgets, dropdowns, hotspot
  styling, cell/row colors, symbols, icons, exception lights, subtotals, and
  grand totals across all ALV reports.
- [ ] Add report-specific visual contracts for `ALV_GRID`, `ALV_EDIT`,
  `ALV_EVENTS`, `ALV_FORMAT`, `ALV_VARIANTS`, and the restored `ALV_DYNAMIC`
  table. Counts and positions must be checked as well as text.
- [ ] Match tree expanders, connector lines, folder/leaf icons, indentation,
  selected node, hierarchy columns, item-class rendering, and toolbar placement
  in `TREE_MODELS`, `TREES`, `ALV_TREE`, `SALV_TREE`, `DRAG_DROP`, and
  `COMPOSITE`.
- [ ] Remove the 15-16px host overflows in `SALV_HIERSEQ`, `SALV_TABLE`, and
  `SALV_TREE` by sizing toolbar/table/tree content within `CC_MAIN`; do not hide
  the overflow with a blanket mask.
- [ ] Keep the intentional `GRAPHICS` and `ILI_DRAGDROP` capability contracts
  honest. They may differ from optional native controls, but their fallback
  text, geometry, actions, and status must remain explicitly verified.

## Phase 6 - container, dialog, and composite geometry

- [ ] Fix `ZGG_GUI_DOCKING_CONTAINER`: the docked editor must reserve its side
  of the work area, and its text must not overlap the main "Docking container
  state" group. Verify every dock side, extension, resize, float, attach, and
  maximize transition.
- [ ] Remove the 3-4px overflow in every `ZGG_GUI_SPLITTER_CONTAINER` cell.
  Account for borders, sash thickness, toolbar/status bars, and nested-control
  box sizing when distributing row/column percentages.
- [ ] Fix the corresponding splitter-cell overflow in `ZGG_GUI_COMPOSITE` and
  verify the tree, ALV grid, detail pane, and event log remain independently
  visible and scrollable at the reference viewport.
- [ ] Match custom-container, docking-container, dialog-container, and nested
  splitter ownership so child controls render exactly once, stay inside their
  declared host, and preserve z-order and focus.
- [ ] Add geometry checkpoints for modeless dialog move/resize/fullscreen and
  for custom/container lifecycle actions, rather than validating only payload
  text or a state fingerprint.
- [ ] Close the seven-report overlap/clipping baseline and remove those entries
  from `known-failing.json`; no replacement exception is allowed without a new
  native-reference audit.

## Phase 7 - compare meaningful interaction states

- [ ] Extend the gg-gui manifest with named screenshot checkpoints for actions
  that reveal the report's purpose. Keep the initial screenshot, but also
  capture the important post-action surfaces.
- [ ] Capture generated/internal/external content states for `HTML_VIEWER` and
  `ABAP_BROWSER`, loaded/cleared/error states for `PICTURE`, and the actual
  modal child selection screen for `MODAL_SELSCREEN`.
- [ ] Capture popup/F1/F4/confirmation states for `DIALOGS_HELP`, active tabs
  and swapped subscreens, table-control scrolling/cursor state, and variant
  save/load/delete state.
- [ ] Capture ALV selection/edit/sort/filter/subtotal/style states; tree
  expand/collapse/select/lazy-load states; TextEdit wrap/read-only/protected
  states; and splitter/docking resize states.
- [ ] Make interaction acceptance require both the expected server-owned state
  change and the expected rendered checkpoint. A changed fingerprint with a
  visually missing result must fail.
- [ ] Publish checkpoint thumbnails and diffs beneath each report card, grouped
  by journey, with deterministic fixture values and no hidden time/user noise.

## Phase 8 - verification and rollout

- [ ] Per batch run `npm run lint`, `npm run unit`,
  `npm --prefix converter run test:unit`,
  `npm --prefix converter run test:gg-gui`,
  `npm run test:html-browser`, and `git diff --check`.
- [ ] Record after every batch: converter diagnostics/TODOs, accepted reports,
  stale references, overlap/clipping failures, initial-state visual scores, and
  journey-checkpoint visual scores.
- [ ] Do not update a baseline from browser output. Native-reference changes
  come only from a reviewed gg-gui revision and SAP GUI recapture.
- [ ] Update `scaffold/GUI_HTML_CAPABILITIES.md` only after the corresponding
  control and its visual checkpoints pass.
- [ ] Finish with a clean 50-report initial run, all declared interaction
  checkpoints passing, zero converter TODOs, zero unreviewed visual exceptions,
  and a comparison index that makes native provenance and remaining deltas
  obvious.

## Not defects - do not hide or "fix"

- [ ] Deterministic browser fixture values (date, time, user, client, host) are
  intentionally different from old SAP session snapshots. Normalize these
  specific values in comparison metadata; do not make the runtime
  nondeterministic to imitate a capture.
- [ ] Fixed-length ABAP truncation documented in PLAN11 remains faithful source
  behavior.
- [ ] `GRAPHICS` and `ILI_DRAGDROP` may retain explicit capability boundaries
  where the native technology is unavailable. They still require complete,
  visible, interactive fallback contracts.
- [ ] Accessibility markup and browser-safe security boundaries are required
  improvements over SAP GUI. Visual fidelity work must not remove them; compare
  their visible presentation while preserving their semantics.
- [ ] The open-abap browser header, menus, command field, global navigation
  toolbar, and global footer/status bar are product chrome, not gg-gui report
  content. Freeze them and exclude them from native-reference parity scoring.
- [ ] A stale or wrong native screenshot is not evidence that the browser is
  correct. Recapture or quarantine the reference explicitly.

## Recommended delivery order

- [ ] **Batch A:** Phase 0 and Phase 1. Establish authoritative references and
  gates that expose the real gap before changing rendering.
- [ ] **Batch B:** Phase 2. Remove the 33 converter omissions and replace the
  dynamic ALV capability boundary with the real table.
- [ ] **Batch C:** Phase 3 and the selection/list portions of Phase 4. Shared
  content layout, typography, field styling, and local action placement produce
  the largest cross-report gain without changing browser chrome.
- [ ] **Batch D:** Complete Phase 4 and Phase 5. Close table-control, ALV, SALV,
  and tree content/geometry differences.
- [ ] **Batch E:** Phase 6. Remove the seven known overlap/clipping failures and
  lock nested-container geometry.
- [ ] **Batch F:** Phase 7 and Phase 8. Add visual interaction checkpoints,
  recapture the full suite, ratchet budgets, and publish the final comparison.
