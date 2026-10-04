# Open items: example programs, converter, host

Found while rewriting the example programs as real ABAP and regenerating their
classes with the converter (see examples/zgg_ex_NNN.prog.abap).

## Needs a decision

- **Standard list functions are not native (092–095).** On SAP, page
  scrolling (`P--`, `P-`, `P+`, `P++`), Find (`%SC`, `%SC+`), Print (`PRI`)
  and Download (`%PC`) are run by the list processor and never reach
  `AT USER-COMMAND`. The host has no implementation: the toolbar buttons send
  the codes to the program. The hand-written zcl_gg_ex_092..095 (via
  zcl_gg_rich_list_base) fake them in program code. Implement them in the
  host, then 092–095 become plain lists.
- **Event output does not open a detail list (066, 085).** Output written in
  `AT USER-COMMAND` or `AT LINE-SELECTION` is appended to the basic list; on
  SAP it forms a new list level (`sy-lsind` 1) that replaces the basic list on
  the screen until Back. Same root as the missing list-level stack below.
- **No list-level stack (083).** Every request re-runs the report and applies
  one line selection to the basic list (`iv_line_level = 1`), so a line of a
  detail list cannot be chosen: level-2 drill-down does not work. The runtime
  would have to keep the path of chosen lines and replay it.
- **PBO runs twice per round trip.** The host replays the PBO of the shown
  screen at the start of a request (it rebuilds the screen's states that way),
  then runs PAI, then PBO. PBO after PAI now always runs with the real screen
  values, as on SAP (before, it ran only for screens with a GUI status, on a
  copy of the values, so a control changed in PBO showed one round trip late,
  e.g. zgg_ex_132, 148). A PBO that is not idempotent (a counter) counts twice;
  converter/test/behavioral-generated.mjs expects 5 where SAP gives 4. Fix:
  keep the screen states of the last response instead of replaying PBO.
- **The list page shows the GUI status name** (`SHELL66`, `BACK`) as text
  above the list (`.gg-list-status`, zcl_gg_host_renderer); SAP never shows
  it. The hand-written 044, 062, 092 and 151–159 use the status name as a
  state display and their specs assert it, so removing it goes with the
  decision on those examples.
- **GUI statuses for 044, 059–062.** The programs `SET PF-STATUS` without a
  `<CUA>` in their prog.xml; the hand-written classes invent the icon bars.
- **Dialog examples 064, 099–116, 162, 163.** The hand-written classes are
  dynpro programs, the programs define no screens. zcl_gg_rich_dynpro_base
  (100) derived P_OUTPUT in PBO and relied on PBO not following PAI; its PBO
  now keeps an output PAI set.
- **151–159** have hand-written classes but no program. They still use
  zcl_gg_host_surface (zcl_gg_plan9_examples_base), an invented surface
  renderer the generated examples no longer need.
- **019, 020, 032, 058** pass converter parity only because
  behavioral-generated.mjs injects metadata the repo lacks (fixed values,
  DDIC, dynpro screens).

## Converter

- `FORMAT` replaces the whole current format (`set_format`); on SAP it changes
  only the options it names, so `FORMAT INTENSIFIED ON` after
  `FORMAT COLOR ...` loses the color.
- `WRITE` of a typed date or time field prints the raw value (`20260830`);
  SAP uses the user's format. Date masks (`DD/MM/YYYY` ...) are reported as
  unsupported.
- `DECIMALS 0` is not distinguishable from no `DECIMALS` in
  `ty_write_format`.
- A continuation whose tail contains `LIST_FROM_MEMORY` replaces the
  program's code with its own "write every memory line" body
  (class-source.mjs, resume dispatcher). The `LIST_FROM_MEMORY` lowering also
  takes the parameter name (`listobject`) as the target instead of the actual.
  No `abaplist` DDIC object exists to write `LIST_TO_ASCI` properly.
- `READ LINE n INDEX i` takes `i` as the line index (lower-statements.mjs).
- Regenerating a class with local event-handler classes writes new helper
  classes `zcl_..._h1_1` when the old `zcl_..._h1` file still exists (the CLI
  sees the name as taken); delete the old helpers before regenerating.
- Lowering writes each statement on one line; the abaplint quick fixes of
  `line_break_multiple_parameters`, `align_parameters`,
  `unnecessary_chaining` and `indentation` are applied to the generated
  source (converter/src/emit/style-fixes.mjs). Still on one line: calls with
  several parameter sections (`EXPORTING ... CHANGING ...`),
  `CREATE OBJECT ... EXPORTING`, `VALUE #( ... )` table constructors and
  string template concatenations.
- Fixed in this batch: PAI took every elementary global back from the screen
  values, so a value an event handler set before PAI was lost; it now takes
  only the screen's input fields (and tabstrip active tabs), as SAP's field
  transport does. Static methods of helper classes get their `IMPORTING
  io_owner io_session` on separate lines; SET HANDLER inside the helper class
  itself no longer names its own class (`prefix_is_current_class`).
- Text symbols (`TEXT-001`, `'text'(001)`) stayed in the class without a text
  pool, so the class failed `check_text_elements`. The converter now writes
  the class's `.clas.xml` with the used `I` entries of the program's text
  pool (converter/src/emit/class-xml.mjs); the transpiler reads class text
  pools. Titles and GUI status texts outside 7-bit ASCII are written as UTF-8
  bytes (`cl_abap_codepage=>convert_from( CONV xstring( ... ) )`,
  converter/src/emit/abap-text.mjs). Still open: a non-ASCII literal written
  in the program itself (`WRITE 'é'`) is copied as is and fails
  `7bit_ascii`; a titlebar with `&1` operands and non-ASCII text too.
- converter/test/transpile-generated.mjs converts each example with its
  .prog.xml and screens now, and writes the class text pools.
- converter/test/transpile-generated.mjs did not write the helper classes of
  examples with local classes, so their main classes failed the check; fixed.

## open-abap classes (src/)

- `src/ddic/pools/cntb.type.abap`: the toolbar button types differ from SAP's
  type group CNTB (SAP: `cntb_btype_button` 0, `dropdown` 1, `menu` 2, `sep`
  3, `group` 4, `check` 5); `cntb_btype_menu` is missing.
- `cl_gui_picture=>load_picture_from_url` returned 0 for success and 4 for a
  failure; SAP returns 1 and 0. Fixed, together with the gg-gui template
  zgg_gui_picture that tested the inverted value.
- Icons without an alias in zcl_gg_host_icons, for example `icon_okay` given
  as `@0V@`, `ICON_FILTER`, `ICON_SORT_*`, `ICON_EXECUTE_OBJECT`,
  `ICON_CANCEL`, fall back to the help or database icon.
- `MTREEITM`, SAP's item structure of list and column trees, was missing;
  added. The repository's `MTREEITEM` is no SAP name (still used by a test of
  cl_gui_control).
- ALV grid, fixed: `refresh_table_display` did not read the output table
  again (changed rows, hidden columns stayed); `is_layout-grid_title` was not
  shown; rows were always striped regardless of `zebra`; a catalog entry
  without `inttype` printed dates raw; `toolbar` was never raised, so
  application toolbar buttons did not exist; `check_changed_data` did
  nothing.
- ALV grid, open: standard functions other than select all, deselect all,
  append row and delete rows do nothing (sort, filter, find, sum, print,
  export, layout and variant dialogs); the row selector is a "Select"
  checkbox column; the error log of `data_changed` shows `msgv1`..`msgv4`
  only (no message class lookup) and does not mark the bad cells; `onf4`,
  `menu_button`, `context_menu_request` and drag and drop are not raised.
- Filters compared numbers as text (`90 GE 100` was true) in cl_gui_alv_grid
  and cl_salv_table; fixed.
- SALV, fixed: sorts (with subtotals) and aggregations were ignored;
  `set_top_of_list`/`set_end_of_list` had the wrong signature and showed
  nothing; the form classes (`cl_salv_form_layout_grid`, `_flow`, `_text`,
  `_label`, `_header_info`) were stubs returning no objects. In a container
  the SALV events `double_click`, `link_click` and `added_function` now
  come from the grid, and `get_selections( )->get_selected_rows( )` reads the
  user's selection.
- SALV, open: a fullscreen SALV list raises no events and transports no
  selection; selected row numbers assume no filter hides rows; form `rowspan`,
  `set_column_label_for` and layout data (`set_h_align`) are ignored.
- Trees, fixed: `cl_gui_simple_tree->add_nodes` cleared the existing nodes
  and showed new nodes expanded; item trees took a node's text from an item
  named `NODE` instead of the hierarchy column (column tree) or the first item
  (list tree); `cl_gui_alv_tree->add_node` kept a reference to the caller's
  variable, so every node showed the last line.
- Trees, open: a list tree does not show its `hierarchy_header`; items of
  class checkbox, button and link are not interactive and raise no item
  events; node images (`n_image`) are not shown in simple and list trees.
- `cl_gui_chart_engine` drew a placeholder; it now draws SimpleChartData
  as SVG (chart types Columns, Bars, Lines, title from the customizing) with
  the values as a table. Pie, stacked, 3-D and customized colors are not
  drawn. `cl_gui_barchart` (SAP's Gantt-style bar chart) has no
  implementation; no example uses it.

## Host

- **Control Framework events, done for the grid, toolbar and trees.** A
  control's submit element posts `gg_control_event=<control id>|<event>|...`
  and its fields `gg-ctl:<control id>:<key>` (selection, edited cells) on
  every round trip. Before PAI, cl_gui_cfw hands the values to the controls
  and dispatches a system event (PAI runs only if a handler sets an OK code,
  which is then not checked against the status); an application event waits
  for `cl_gui_cfw=>dispatch` in PAI or is dispatched after PAI. Routed:
  cl_gui_alv_grid (functions, toolbar, hotspot, double click, button cells,
  row selection, edited cells with `data_changed`), cl_gui_toolbar
  (`function_selected`, static menus), simple/list/column trees (expand with
  `expand_no_children`, `selection_changed`, `node_double_click`).
- **Still not routed:** `SAPEVENT` links of the HTML viewer (128),
  `date_selected` of the calendar (126), `clicked` of a dynamic-document link
  (130), item events of list and column trees; the ALV tree keeps its own
  `TREE_EVENT` transport and the invented OK code `GG_TREE_EVENT`.
- **Text typed into a `cl_gui_textedit` is not transported back** to the
  control: `get_textstream` in PAI returns the program's last text, not the
  user's (zgg_ex_133, 134). An editor is display-only. The new `gg-ctl:`
  field transport is the way to fix it.
- `set_textstream` in PBO on an editor created in an earlier round trip was
  not shown (zgg_ex_132); PBO now follows PAI, recheck.
- **A freed control stays in the page**, hidden (`go_editor->free( )` then a
  new editor in the same container, zgg_ex_117).
- **Dynamic document tables do not render**: `cl_dd_table_element` columns
  filled with `add_column( heading = ... )` and `column->add_text( )` produce
  no table (zgg_ex_129).
- The static context menu of a toolbar button is shown as a permanent list
  next to the toolbar, not as a dropdown (zgg_ex_125).
- zcl_gg_selector is an invented control with no SAP counterpart; it is unused
  since zgg_ex_127 became a dynpro dropdown listbox.
- The list writer starts the first line at column 0 and later lines at
  column 1, which gives double blanks (`I  EQ`) after one-character fields.
- `set_format` replaces the format, see Converter.
- Icons `ICON_FILTER`, `ICON_SORT_*`, `ICON_INFORMATION`-like names without an
  alias fall back to the help icon (zcl_gg_host_icons).
- The workbench lists the classes in build/generated-examples when the host
  is transpiled with build/abap_transpile.start.json (`npm start`), so the
  transaction count in zcl_gg_index.spec.mjs only holds for `npm run unit`'s
  output.

## Transpiler

- Program `AT USER-COMMAND` blocks are compiled (they throw at runtime) while
  `AT LINE-SELECTION` and `AT SELECTION-SCREEN` blocks are dropped;
  `MODIFY LINE` is not supported, so a program with `MODIFY LINE` in
  `AT USER-COMMAND` fails to transpile. zgg_ex_086 modifies its lines in
  `AT LINE-SELECTION` because of this.
- `CREATE OBJECT io_owner->go_tree EXPORTING ...` creates an instance of the
  class of `io_owner`, not of the attribute's declared type. The converter
  works around it in helper classes by naming the type
  (`CREATE OBJECT io_owner->go_tree TYPE cl_gui_list_tree ...`).

## abaplint

- `MODIFY LINE n LINE FORMAT INVERSE ON` does not parse (`INVERSE` without
  `ON` does).
- `USER-COMMAND` together with any `LENGTH` addition is rejected
  (`PARAMETERS p TYPE c LENGTH 2 AS LISTBOX ... USER-COMMAND x`).
