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
that the runtime accepts; undeclared PF keys are rejected. Back is the one
command the program does not own: it is always enabled and leaves the program
for the workbench.

The application icon bar is owned solely by the running report or dynpro's
status. Each `ty_gui_status-icon_bar` entry supplies a non-empty function code,
user-facing label, and catalog icon name; `separator = abap_true` places a
separator immediately before that entry. Duplicate function codes and
incomplete entries are rejected when the status is set. Function-code entries
submit `COMMAND:<function code>` and use the status' active/excluded lists for
their enabled state. An initial icon bar omits the application toolbar; the
workbench index never supplies fallback buttons. Unknown icon names resolve to
the shared safe fallback icon through `zcl_gg_host_icons`.

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
| Containers and splitters | identity, parent, geometry, visibility, child order | semantic `section` layout region | child containment is preserved | region remains usable when exact docking/sash behavior is unavailable |
| `cl_gui_textedit` | text, readonly, cursor, selection, modified | labelled `textarea` | form submission carries the control name | plain textarea |
| `cl_gui_picture` | URL, size, alignment | safe `img` | no unsafe URL is emitted | empty image region |
| `cl_gui_toolbar` | buttons, labels, command, disabled state | `role=toolbar` and submit buttons | command values use `gg_ucomm` | disabled buttons remain visible |
| `cl_gui_html_viewer` | document and current URL | sandboxed `iframe` | load/show/refresh state is observable | escaped `srcdoc`, no script execution |
| `cl_gui_calendar` / selector | focus/selection or selected value | date input or select | values are ordinary form values | native HTML control |
| `cl_gui_alv_grid` | rows, field catalog, selected rows, title | semantic table with headings and one cell per visible field | refresh/sort/filter toolbar commands | scalar row text when no field-catalog component matches |
| Tree controls | node key, parent, text, expanded, selected, hidden | accessible `ul`/`li` tree with parent metadata | selection/expansion state is retained | flat ordered tree when a native tree widget is unavailable |
| SALV table | row count, header | semantic table section via `get_html` | model methods remain safe no-ops | row-count table when generic row reflection is unavailable |
| Graphics/chart | payload and control identity | labelled figure/chart fallback | data/render calls are observable | text figure; no raw untrusted SVG |
| browser/progress/timer/frontend services | last requested content or lifecycle intent | host-owned state only | explicit capability result and user-activated action | no desktop operation is reported as successful without browser evidence |

Security invariant: payloads are escaped at the registry boundary, URLs are
allow-listed, HTML viewer content is sandboxed, and no HIDE or continuation
state is copied into the browser payload.

Examples 148 and 149 preserve the SAP bar-chart/chart-engine intent through
the browser-safe graphics model. Because the browser host does not reproduce
the desktop graphics controls, both expose labelled figures with a semantic
table of series and values; application data is never emitted as raw SVG.

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
  save/apply/switch/delete/cleanup lifecycle.
- `ZGG_EX_158` preserves typed header/item rows and totals in a semantic SALV
  fallback table.
- `ZGG_EX_159` renders a deterministic nine-month calendar window with ISO
  week ranges and navigation actions.
