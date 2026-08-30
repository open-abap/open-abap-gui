# GUI HTML capability table

The source compatibility layer keeps its control model in the registry owned by
`cl_gui_control`. Each row below describes the browser-facing behavior. Methods
not listed as model or render are intentionally no-ops and must not assert or
abort a host request.

When a report creates GUI controls during its host execution, the list-page
renderer embeds the registry's fragment output in the same HTML document. The
standalone `cl_gui_control=>render_html( )` form remains available for direct
control-host consumers; `iv_document = abap_false` is the embedding form.

The standard toolbar of the shell is disabled unless the running program
activates a function code through its CUA status, so
`ty_gui_status-active_ucomm` decides which commands a page offers and
`excluded_ucomm` removes them again. An active command submits
`COMMAND:<function code>`, and the program receives it like any other user
command. Back is the one command the program does not own: it is always
enabled and leaves the program for the workbench.

The application icon bar is owned by the same status. Each
`ty_gui_status-icon_bar` entry supplies the visible label, icon, and optional
function code; function-code entries submit `COMMAND:<function code>` and use
the status' active/excluded lists for their enabled state. The workbench index
supplies its launchpad icons explicitly.

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
| browser/progress/timer/frontend services | last requested content or lifecycle intent | host-owned state only | no browser action is fabricated | intentional no-op documented in `ANORMALIES.md` when runtime support is the blocker |

Security invariant: payloads are escaped at the registry boundary, URLs are
allow-listed, HTML viewer content is sandboxed, and no HIDE or continuation
state is copied into the browser payload.
