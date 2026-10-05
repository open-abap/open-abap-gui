# Open items: example programs, converter, host

Found while rewriting the example programs as real ABAP and regenerating their
classes with the converter (see examples/zgg_ex_NNN.prog.abap).

## Needs a decision

Nothing open.

## Converter

- `FORMAT` replaces the whole current format (`set_format`); on SAP it changes
  only the options it names, so `FORMAT INTENSIFIED ON` after
  `FORMAT COLOR ...` loses the color.
- `WRITE` of a `c` field drops its trailing blanks (`|{ field }|`), so the
  columns after it move left (083: `0400 Frankfurt New York`).
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
- Lowering writes each statement on one line; style fixes break up some of
  them (converter/src/emit/style-fixes.mjs). Still on one line: calls with
  several parameter sections (`EXPORTING ... CHANGING ...`),
  `CREATE OBJECT ... EXPORTING`, `VALUE #( ... )` table constructors and
  string template concatenations.
- A non-ASCII literal written in the program itself (`WRITE 'é'`) is copied as
  is and fails `7bit_ascii`; a titlebar with `&1` operands and non-ASCII text
  too.
- Module `DATA` is local to the call; on SAP it is global data of the
  program and keeps its value.
- The help-request dispatch reads the help text from a value named
  `GV_RESULT` (class-source.mjs), which no program defines. A POH module on
  SAP shows its help itself (`HELP_OBJECT_SHOW` and similar).

## open-abap classes (src/)

- `src/ddic/pools/cntb.type.abap`: the toolbar button types differ from SAP's
  type group CNTB (SAP: `cntb_btype_button` 0, `dropdown` 1, `menu` 2, `sep`
  3, `group` 4, `check` 5); `cntb_btype_menu` is missing.
- Icons without an alias in zcl_gg_host_icons, for example `icon_okay` given
  as `@0V@`, `ICON_FILTER`, `ICON_SORT_*`, `ICON_EXECUTE_OBJECT`,
  `ICON_CANCEL`, fall back to the help or database icon.
- The repository's `MTREEITEM` is no SAP name (SAP's is `MTREEITM`); a test of
  cl_gui_control still uses it.
- ALV grid layouts: Manage layouts (`&MAINTAIN`), user-specific versus global
  layouts (the `/` prefix and `i_save` U/X are not enforced), and column order
  changes in the dialog are missing.
- ALV grid: standard functions other than select all, deselect all, append
  row, delete rows and the layouts do nothing (sort, filter, find, sum,
  print, export); the row selector is a "Select" checkbox column; the error
  log of `data_changed` shows `msgv1`..`msgv4` only (no message class lookup)
  and does not mark the bad cells; `onf4`, `menu_button`,
  `context_menu_request` and drag and drop are not raised.
- SALV: a fullscreen SALV list raises no events and transports no selection;
  selected row numbers assume no filter hides rows; form `rowspan`,
  `set_column_label_for` and layout data (`set_h_align`) are ignored.
- Hierarchical-sequential SALV (zgg_ex_158): a header line cannot be expanded
  or collapsed in the browser.
- Drag and drop (zgg_ex_153): no keyboard alternative; only the simple tree
  drags and only the grid takes drops (no grid drag source, no tree drop
  target, no `on_drop_get_flavor`); the effect (copy or move) is not shown
  while dragging.
- Trees: a list tree does not show its `hierarchy_header`; items of class
  checkbox, button and link are not interactive and raise no item events;
  node images (`n_image`) are not shown in simple and list trees.
- `cl_gui_chart_engine` does not draw pie, stacked, 3-D or customized colors.
  `cl_gui_barchart` (SAP's Gantt-style bar chart) has no implementation; no
  example uses it.

## Host

- Control Framework events not routed yet: `clicked` of a dynamic-document
  link (130) and item events of list and column trees. The ALV tree keeps its
  own `TREE_EVENT` transport and the invented OK code `GG_TREE_EVENT`.
- Frontend services: clipboard, `execute`, directories, registry and the
  other methods besides the file dialogs, `gui_download` and `gui_upload` are
  stubs.
- A request from a page that is no longer current gets the raw JSON
  `{"valid":false,"error":"Stale host page"}` as the page. The timer page
  drops a second submit once one is under way, but double clicks and two tabs
  still hit it.
- **Text typed into a `cl_gui_textedit` is not transported back** to the
  control: `get_textstream` in PAI returns the program's last text, not the
  user's (zgg_ex_133, 134). An editor is display-only. The `gg-ctl:` field
  transport is the way to fix it.
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
- List levels:
  - The replay runs START-OF-SELECTION and every event again for each
    request. A program with side effects outside its own data (a database
    update, a file) repeats them; on SAP the program keeps running.
  - The 20-level limit and `sy-lsind` greater than the next level are not
    checked.
- List processor:
  - Find has no options (case, from the cursor) and does not wrap around;
    SAP GUI shows the hits in a list when there are several.
  - Function keys reach only dynpro pages, so F21–F24, Ctrl+F and Ctrl+P do
    nothing on a list; PgUp and PgDn scroll it natively.
  - Save to local file has no rich text or clipboard option, and Print has no
    print parameters; the browser's dialogs take their place.
- Dynpro:
  - `SCREEN-REQUIRED = 2` (shown as required, checked by the program) is not
    supported; states know required or not.
  - A popup answer still replays the PAI that called the popup.
  - An I message shows in the message area; on SAP it is a dialog box.
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

## abaplint

- The indentation rule does not take `END-OF-PAGE` as the start of an event
  block; 091 and 092 write that block unindented.
