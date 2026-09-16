# GUI HTML capability table

The source compatibility layer keeps its control model in the registry owned by
`cl_gui_control`. Each row below describes the browser-facing behavior. Methods
not listed as model or render are intentionally no-ops and must not assert or
abort a host request.

When a report creates GUI controls during its host execution, the list-page
renderer embeds the registry's fragment output in the same HTML document. The
standalone `cl_gui_control=>render_html( )` form remains available for direct
control-host consumers; `iv_document = abap_false` is the embedding form.

Application examples use the typed `zcl_gg_host_surface=>ty_surface` contract
through `zcl_gg_host_surface=>set_surface( )` for browser-facing documents,
tables, trees, charts, alerts, and composites. This host adapter keeps the
public definitions of the SAP GUI control classes unchanged. The shared
renderer owns semantic elements, escaping, URL policy, form transport, and
accessible names. Example code must not construct renderer-specific HTML;
`set_external_html( )` remains a compatibility seam for legacy control
implementations only.
The standard toolbar of the shell is disabled unless the running program
activates a function code through its CUA status, so
`ty_gui_status-active_ucomm` decides which commands a page offers and
`excluded_ucomm` removes them again. An active command submits
`COMMAND:<function code>`, and the program receives it like any other user
command. The runtime repeats the active/excluded check server-side before it
dispatches a callback. `active_pf_keys` similarly declares the AT PFnn events
that the runtime accepts; undeclared PF keys are rejected. Back is always
available as the shell escape hatch; when the running program activates BACK
in its CUA status, the same command is dispatched to that program first,
otherwise it leaves the program for the workbench.

The application icon bar is owned solely by the running report or dynpro's
status. Each `ty_gui_status-icon_bar` entry supplies a non-empty function code,
user-facing label, and catalog icon name; `separator = abap_true` places a
separator immediately before that entry. Duplicate function codes and
incomplete entries are rejected when the status is set. Function-code entries
submit `COMMAND:<function code>` and use the status' active/excluded lists for
their enabled state. An initial icon bar omits the application toolbar; the
workbench index never supplies fallback buttons. Unknown icon names resolve to
the shared safe fallback icon through `zcl_gg_host_icons`.

Example 132 exercises the shared Control Framework lifecycle as one
server-owned session: the text editor and local toolbar retain focus,
visibility, enablement, geometry, event-registration, refresh/reset, and
deterministic timer state. Closing the host session cancels that timer.

The runtime chrome has no breadcrumb band. A program that wants to show where
the user is puts that in its own page content, next to the rest of what it
renders, rather than handing typed crumbs to the shell.

## Transaction commands and navigation

Runnable workbench applications publish a stable transaction code through
`zif_gg_transaction_v1` and exactly one executable contract,
`zif_gg_report_v1` or `zif_gg_dynpro_v1`. A report may additionally implement
the auxiliary `zif_gg_screen_provider_v1`; the host adapts it at a `CALL
SCREEN` boundary without changing the registry kind from REPORT. `zcl_gg_transaction_registry`
is the single discovery, validation, normalization, lookup, and
launch-authorization catalog. Codes are case-insensitive, rendered
canonically in upper case, and must contain only letters, digits, underscores,
or valid namespace separators.

The command field is a real `POST /transaction` form. Its supported syntax is
`/n<tcode>`; `/n` is case-insensitive and surrounding whitespace is accepted.
Plain tcodes, `/o...`, missing tcodes, trailing tokens, and unknown tcodes
produce an accessible error and do not start a program. A command entered from
a running report or dynpro validates the target first, then atomically closes
the submitted current session/page pair before starting the new transaction.
An invalid or stale pair leaves the old session open. Workbench links use
`GET /transaction?tcode=...`; direct `/<class_name>` URLs remain compatibility
routes only. Those routes resolve example classes through the transaction
registry and explicitly allow-list the integration fixtures; an arbitrary URL
class name is never passed to dynamic construction.

| Family | Model state | HTML representation | Events/actions | Fallback |
| --- | --- | --- | --- | --- |
| Containers and splitters | identity, parent, dynpro coordinates, lifetime, geometry, visibility, child order | semantic `section` layout region | child containment and lifecycle diagnostics are preserved | region remains usable when exact docking/sash behavior is unavailable |
| `cl_gui_textedit` | text, readonly, cursor, selection, modified, wrapping, fixed font, protected-line range, toolbar/status visibility | labelled `textarea` with semantic toolbar/status regions | form submission carries the control name; clear/restore and stream/table state stay server-owned | desktop file load/save returns an explicit unsupported result; plain textarea remains usable |
| `cl_gui_picture` | allow-listed URL, alt text, size, border, fit/alignment, loaded/rejected/empty state | labelled `img` in a stateful picture region | URL loading and display mode are server-owned; rejected URLs never become image sources | empty/rejected image region remains visible |
| `cl_gui_toolbar` | buttons, labels, command, toggle state, menus, separators, visibility | distinct `role=toolbar` with native buttons and keyboard-focusable overflow menu | command values remain server-authorized; menu and button events are observable | disabled items remain visible and unsupported native popup behavior is not fabricated |
| `cl_gui_html_viewer` | document and current URL | sandboxed `iframe` | load/show/refresh state is observable | escaped `srcdoc`, no script execution |
| `cl_gui_calendar` / selector | focus/selection or selected value | date input or select | values are ordinary form values | native HTML control |
| `cl_gui_alv_grid` | rows, field catalog, selected rows, title | semantic table with headings and one cell per visible field | refresh/sort/filter toolbar commands | scalar row text when no field-catalog component matches |
| `cl_gui_alv_tree` | hierarchy nodes, typed field catalog rows, expanded/selected state | accessible hierarchy plus typed semantic columns and totals | lazy child loading, add/collapse/expand/select, calculation and toolbar actions | hierarchy remains usable when the native tree widget is unavailable |
| Classic ALV function modules | field-catalog merge, grid/list display, header/item display, blocks, popup/events, variants, commentary | semantic SALV/table output with explicit classic wrappers and grouped block sections | metadata, event names, safe default variant, popup selection, and callback state are server-owned | renderer failure remains an explicit capability message |
| Tree controls | node key, parent, text, expanded, selected, hidden | accessible `ul`/`li` tree with parent metadata | selection/expansion state is retained | flat ordered tree when a native tree widget is unavailable |
| SALV table | row count, header, columns, functions, formatting, rows | semantic table section via `get_html` | model methods, toolbar actions, and callbacks retain server-owned state | row-count table when generic row reflection is unavailable |
| SALV tree | hierarchy nodes, typed item cells, selection | full-width semantic tree table with links, checkboxes, buttons, and dropdowns | link/double-click/checkbox/key events plus add/expand/collapse actions | API failure is surfaced as an explicit semantic fallback |
| Graphics/chart | payload, control identity, capability state | labelled figure with semantic data table and optional color input | data/render calls and color updates are server-owned | native bar/chart-engine/GFW controls are explicitly unavailable; no raw untrusted SVG |
| browser/progress/timer/frontend services | last requested content or lifecycle intent | host-owned state only | explicit capability result and user-activated action | no desktop operation is reported as successful without browser evidence |

Security invariant: payloads are escaped at the registry boundary, URLs are
allow-listed, HTML viewer content is sandboxed, and no HIDE or continuation
state is copied into the browser payload.

Examples 148 and 149 preserve the SAP bar-chart/chart-engine intent through
the browser-safe graphics model. Because the browser host does not reproduce
the desktop graphics controls, they expose labelled figures with semantic
tables of series and values, and example 148 provides a server-validated color
input. `CL_GUI_GP_PRES` returns an explicit unsupported status and its fallback
text is rendered as capability evidence; application data is never emitted as
raw SVG.

## Verified PLAN9 contracts 152-159

The post-catalog examples are transaction-discovered automatically by
`zcl_gg_transaction_registry`; their metadata appears in the workbench catalog
without a second hand-maintained inventory. Each example keeps its state in the
report instance and publishes only typed surfaces and declared commands.

- `ZGG_EX_152` drives timer start, stop, interval, reuse, and tick state with
  an explicit deterministic clock; it never schedules browser background work.
- `ZGG_EX_153` exposes opaque node payloads and server-validated move/copy,
  reject, undo, and keyboard-equivalent actions.
- `ZGG_EX_154` reports upload/download/clipboard intent while refusing
  desktop-only directory and registry claims.
- `ZGG_EX_155` keeps a modeless dialog container and its parent lifecycle
  separate, including geometry, focus, and close actions.
- `ZGG_EX_156` renders typed confirm, input, selection, message, and progress
  popup states with explicit OK/cancel return actions.
- `ZGG_EX_157` keeps ALV layout variant state report-local and supports the
  save/apply/switch/delete/cleanup lifecycle with safe names, ownership,
  explicit confirmation, and a non-persistent handle.
- `ZGG_EX_158` preserves typed header/item rows, binding keys, grouped level
  sections, quantities, currencies, and totals through the SALV HIERSEQ renderer;
  construction failure remains an explicit semantic fallback.
- `ZGG_EX_159` renders a deterministic nine-month calendar window with ISO
  week ranges, bounded ISO date input, focus/selection state, single/range
  modes, marks, readback, recreation, and navigation actions.
- The legacy ILI drag/drop control renders an explicit ActiveX-unavailable
  fallback text area while preserving geometry, visibility, mode, and menu
  state; no native drag/drop success is fabricated.
- Tree surfaces expose stable opaque node keys, hierarchy levels, expansion and
  selection state, icons, text/checkbox/button/link/editable item semantics,
  hidden lazy children, and escaped explanatory text alongside server actions.
- Simple, list, and column tree models expose deterministic state summaries,
  including model kind, node count, expansion, and selection, so comparison
  output describes actual backend state rather than static labels.
- The tree/grid drag-drop example keeps opaque node IDs and validates move,
  copy, reject-next, undo, keyboard-equivalent actions, and payload inspection
  on the server; pointer-unavailable fallback remains explicit.
- ALV grid rendering preserves field-catalog visibility and types, typed
  editable/checkbox/dropdown/hotspot cells, emphasis and icon metadata,
  selection, criteria/sort state, subtotals/totals, variant metadata, and
  refresh/print/XML/variant toolbar affordances.
- Dynamic and editable ALV examples keep runtime structure/style metadata,
  typed totals, dropdown/F4/hotspot affordances, changed-data validation,
  append/copy/delete mutations, and report-local Save/Discard draft state.
- ALV event examples retain an explicit report event log for toolbar/menu,
  delayed selection, print, data-change, drag/drop, application, hotspot, and
  double-click dispatch; the event log is not inferred from browser markup.
- ALV tree rendering preserves hierarchy keys, typed field-catalog columns,
  expansion/selection, lazy children, mutations, totals, and explicit toolbar
  actions in a server-owned semantic fallback.
- SALV HIERSEQ renders header and item sections with binding metadata,
  parent-key attributes, numeric total rows, and a full-width scrolling wrapper;
  the classic ALV adapters route grid/list/block output through the same
  semantic renderer and keep unsupported desktop behavior explicit.
The modeless dialog example (`zcl_gg_ex_155`) uses a non-modal dialog region with
server-owned position, size, focus, and close state. Its dialog control exposes
move, resize, focus, and close lifecycle events; the parent remains interactive
while the dialog is open and closing it removes the child control.

The docking example (`zcl_gg_ex_120`) keeps a left dock and a neighboring main
diagnostic table as separate server-owned regions. Dock side, extension, visible,
and floating state survive each action; unsupported desktop docking behavior is
represented by the semantic region and its explicit state table.

Examples `zcl_gg_ex_118` and `zcl_gg_ex_119` expose nested splitter/easy-splitter
grids with server-owned sash positions and minimum pane sizes. The panes retain
editor and sandboxed HTML-viewer content, and sash actions clamp values instead
of allowing an invalid or unusably small pane.

The analytics cockpit (`zcl_gg_ex_150`) keeps its application toolbar, ALV grid,
tree, chart, nested editor/viewer splitter, status, and bottom action row in one
composite view. Each action remains command-authorized and the report retains
the selected filter context when the view is refreshed.

The ABAP-browser example (`zcl_gg_ex_151`) keeps the complete document in the
HTML viewer, with report-owned status/instruction fields, repository navigation
history, source staging state, a print toolbutton, and the eight helper actions
from the reference report. HTML/XML, malformed, and empty input results are
shown explicitly without claiming unsupported desktop behavior.
