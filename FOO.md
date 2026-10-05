# Open items: example programs, converter, host

Found while rewriting the example programs as real ABAP and regenerating their
classes with the converter (see examples/zgg_ex_NNN.prog.abap).

## Needs a decision

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
  converter/test/behavioral-generated.mjs expects 6 where SAP gives 5. Fix:
  keep the screen states of the last response instead of replaying PBO.
- **The list page shows the GUI status name** (`SHELL66`, `BACK`) as text
  above the list (`.gg-list-status`, zcl_gg_host_renderer); SAP never shows
  it. The hand-written 044, 062 and 151–159 use the status name as a
  state display and their specs assert it, so removing it goes with the
  decision on those examples.
- **GUI statuses for 044, 059–062.** The programs `SET PF-STATUS` without a
  `<CUA>` in their prog.xml; the hand-written classes invent the icon bars.
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
- Fixed with 151–159: a screen without PBO (or PAI) modules got a `RETURN`
  before the values were written back (unreachable code); a static method of
  a local class defined on one line (`CLASS-METHODS m IMPORTING p TYPE t`) got
  the owner and session parameters unaligned, and a positional argument to it
  became an upper case named one (`IV_HTML = ...`).
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
- Fixed with the dialog examples (064, 099–116, 162, 163):
  - Flow logic is read statement by statement, not line by line, so
    `LOOP AT itab ... WITH CONTROL tc` may go on with `CURSOR` on the next
    line.
  - A table control is bound to the table its PBO loops over. It was
    `GT_` plus the control name.
  - `FIELD f.` and `FIELD: a, b.` are field steps.
  - `CONTROLS tc TYPE TABLEVIEW` exchanges `TOP_LINE` and `LINES`, and
    `sy-loopc` is the number of visible lines.
  - What a module changed before `CALL SCREEN`, `LEAVE` or an error message
    is written back.
  - PBO and PAI modules are dispatched in the private methods
    `output_modules` and `input_modules`.
  - Table controls exchange their values in `table_values_in` and
    `table_values_out`.
  - Module `DATA` is declared at the top of the method.
  - A comment right before `MODULE` or `FORM` goes with that block, not with
    the end of `START-OF-SELECTION`.
  - `|a| && |b|` is written as one template.
  - `SET PF-STATUS ... EXCLUDING itab` copies the table without a redundant
    `CONV`.
- Module `DATA` is local to the call; on SAP it is global data of the
  program and keeps its value.
- `ULINE` was lowered with an invented `set_position( 5 )` after it, so the
  next `WRITE /` produced a blank line; after `ULINE` the list cursor stands
  at the start of the next line, as on SAP. The hand-written zcl_gg_ex_003
  had the same column 5 and is fixed too.
- abaplint's indentation rule does not take `END-OF-PAGE` as the start of an
  event block; 091 and 092 write that block unindented.
- The help-request dispatch reads the help text from a value named
  `GV_RESULT` (class-source.mjs), which no program defines. A POH module on
  SAP shows its help itself (`HELP_OBJECT_SHOW` and similar).
- abaplint no longer checks `.prog.screen_NNNN.abap` files, because flow logic
  is not ABAP (abaplint.jsonc `exclude`).

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
- ALV grid, layouts (zgg_ex_157): Change layout (`&COL0`), Choose layout
  (`&LOAD`) and Save layout (`&SAVE`) are dialogs of the grid; a layout holds
  the visible columns in order and the sort, is kept in cl_alv_variant for the
  lifetime of the server (no database), and the default layout of the
  report/handle starts the grid. `i_save` takes A/U/X as on SAP. Open: Manage
  layouts (`&MAINTAIN`), user-specific versus global layouts (the `/` prefix
  and `i_save` U/X are not enforced), column order changes in the dialog.
- ALV grid, open: standard functions other than select all, deselect all,
  append row, delete rows and the layouts do nothing (sort, filter, find,
  sum, print, export); the row selector is a "Select"
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
- Drag and drop (zgg_ex_153): a tree node with a `DRAGDROPID` and a grid with
  `s_dragdrop-row_ddid`/`grid_ddid`/`cntr_ddid` are HTML5 drag sources and
  drop targets; a drop raises `on_drag` of the simple tree, `ondrop` of the
  grid and `on_drop_complete`, in SAP's order. Open: no keyboard alternative;
  only the simple tree drags and only the grid takes drops (no grid drag
  source, no tree drop target, no `on_drop_get_flavor`); the effect (copy or
  move) is not shown while dragging.
- Hierarchical-sequential SALV (zgg_ex_158) is one list now, each header line
  followed by its items, with the totals of the aggregated item columns;
  before, it showed two separate tables with invented headings and summed
  columns by their names. Open: expanding or collapsing a header line in the
  browser.
- Trees, open: a list tree does not show its `hierarchy_header`; items of
  class checkbox, button and link are not interactive and raise no item
  events; node images (`n_image`) are not shown in simple and list trees.
- `cl_gui_chart_engine` drew a placeholder; it now draws SimpleChartData
  as SVG (chart types Columns, Bars, Lines, title from the customizing) with
  the values as a table. Pie, stacked, 3-D and customized colors are not
  drawn. `cl_gui_barchart` (SAP's Gantt-style bar chart) has no
  implementation; no example uses it.

## Host

- **Control Framework events, done for the grid, toolbar, trees, timer,
  dialog box, calendar, HTML viewer and drag and drop.** A
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
  Added with 151–159: `cl_gui_timer` counts its `interval` (seconds) down in
  the browser and raises `finished` (system event) once per `run`; the close
  button of a `cl_gui_dialogbox_container` raises `close`, and the dialog box
  sits at its `left`/`top` with its caption (it showed an invented title at a
  fixed position, and nothing in it could be clicked); a day of
  `cl_gui_calendar` raises `date_selected` with the day, week or month of the
  selection style; a `SAPEVENT:` anchor (any case) raises `sapevent` of its
  HTML viewer with `action` and `getdata` (it was posted as a function code).
- **Still not routed:** `clicked` of a dynamic-document link (130), item
  events of list and column trees; the ALV tree keeps its own `TREE_EVENT`
  transport and the invented OK code `GG_TREE_EVENT`.
- Popups, fixed: the answer of a popup replayed PAI with the popup kind as
  function code (`VALUE`, `TABLE`), not the function code that called it; the
  popup markup closed one `</div>` too many, so the screen behind it lost its
  form; the table popup added a "Select row n" button per line and a Row
  column; `POPUP_GET_VALUES` cancelled with returncode 1 instead of `A`.
- Frontend services (zgg_ex_154): `file_save_dialog`/`file_open_dialog` are
  popups of the screen, `gui_download` hands the file to the browser with the
  page, `gui_upload` reads the bytes picked in the open dialog. Only in dialog
  processing; elsewhere they raise `not_supported_by_gui` (or cancel). Open:
  clipboard, `execute`, directories, registry and the other methods are still
  stubs.
- A request from a page that is no longer current gets the raw JSON
  `{"valid":false,"error":"Stale host page"}` as the page. The timer page
  drops a second submit once one is under way (a Stop click meeting the
  timer's round trip), but double clicks and two tabs still hit it.
- A dynpro module's `sy-repid` was empty; the dynpro session now knows its
  program.
- An initial date screen field showed `00.00.0000`; it is blank, as in SAP
  GUI.
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
- Dynpro processing, fixed with the dialog examples:
  - Required fields are checked before PAI ("Fill in all required entry
    fields", cursor on the first empty one); a function of type E skips the
    check and runs `AT EXIT-COMMAND`.
  - BACK counts as an exit command only for a status set by hand without
    function keys. Before, it ran `AT EXIT-COMMAND` everywhere.
  - At the end of PAI the next screen follows: the static one, or the one set
    with `SET SCREEN` (`SET SCREEN` did nothing). Next screen 0 after
    `LEAVE SCREEN` returns to the caller.
  - An E message in a `FIELD` or `CHAIN` module leaves only those fields
    open.
  - `CALL SCREEN` keeps a stack of screen sequences.
  - The cursor of a screen is not carried to the next one.
  - Table controls scroll with `TOP_LINE`; lines past `LINES` are not ready
    for input.
- System toolbar, fixed: each button is a function key (Save F11, Back F3,
  Exit F15, Cancel F12, Print F86, Find F71 and F84, paging F21–F24) and sends the function code the
  status gives that key. Before, it sent the list codes `%EX` and `RW`, so
  Exit and Cancel were disabled on every dialog screen. A status with function
  keys leaves the keys it does not assign inactive. The buttons post the
  screen's form, so the field contents reach PAI, and toolbar buttons no
  longer trip the browser's own required check (`formnovalidate`).
- List processor functions, done with 092–095 (zcl_gg_host_list_processor):
  - A list whose program sets no status has the standard list status: Back,
    Exit `%EX`, Cancel `RW`, Print `PRI`, Find `%SC`, Find next `%SC+`, the
    four paging functions and Save to local file `%PC`. They sit on SAP's
    function keys, and the List and Edit menus offer them. Before, such a
    list had no status, and only the workbench's own Back worked.
  - These functions never reach `AT USER-COMMAND`; Back, Cancel and Exit on a
    list are handled by the runtime as navigation.
  - Paging scrolls the list window (`.gg-work-area`) and Print opens the
    browser's print dialog; neither makes a round trip.
  - Find asks for the term in a dialog box, marks the hit line and scrolls to
    it; Find next goes on from the last hit.
  - Save to local file asks for the format (unconverted, spreadsheet with
    tabs, HTML) and a file name, then downloads the file.
  - The list page no longer adds a "List actions" row with a raw button per
    active or excluded function code (invented).
  - The status menus posted `gg-dynpro-form` on every page, so they did
    nothing on a list; they post the page's form now.
- Open, list processor:
  - Find has no options (case, from the cursor) and does not wrap around;
    SAP GUI shows the hits in a list when there are several.
  - Function keys reach only dynpro pages, so F21–F24, Ctrl+F and Ctrl+P do
    nothing on a list; PgUp and PgDn scroll it natively.
  - Save to local file has no rich text or clipboard option, and Print has no
    print parameters; the browser's dialogs take their place.
  - 044's program handles `PRI` in `AT USER-COMMAND`, which never runs on
    SAP. 044 is still hand-written (see GUI statuses above).
- Open, dynpro:
  - An I message shows in the message area; on SAP it is a dialog box.
  - A function excluded from the status is shown disabled in the
    application toolbar; SAP hides it.
  - An input field's accessible name is its field name, not the text in
    front of it.
  - Required columns of a table control are not checked.
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
- `CLEANUP` blocks are ignored; the converter catches `zcx_gg_control_flow`
  and raises it again instead.
- `line_exists( io_session->get_status( )-exit_ucomm[ table_line = x ] )`, a
  table expression on a method call's result, is translated wrongly: the
  program ended. zcl_gg_host_dynpro copies the table to a variable first.
- `CREATE OBJECT io_owner->go_tree EXPORTING ...` creates an instance of the
  class of `io_owner`, not of the attribute's declared type. The converter
  works around it in helper classes by naming the type
  (`CREATE OBJECT io_owner->go_tree TYPE cl_gui_list_tree ...`).