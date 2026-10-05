CLASS zcl_gg_host_icons DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Local, dependency-free SVG sprite based on the Tabler Icons outline set.
* Keep callers on semantic names so the icon set can be changed centrally.
* SAP icon values (@08@, @08\QTooltip@) and ICON_* constant names resolve
* through one table, which also carries the SAP GUI colour tone and a label.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_icon,
        symbol TYPE string,
        tone   TYPE string,
        label  TYPE string,
      END OF ty_icon.

    CLASS-METHODS class_constructor.

    CLASS-METHODS sprite
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS refresh_svg
      RETURNING
        VALUE(rv_html) TYPE string.

    "! Resolves a semantic name, sprite symbol, ICON_* name or @xx@ value.
    "! The returned symbol is initial when the name is unknown.
    CLASS-METHODS resolve
      IMPORTING
        iv_name        TYPE string
      RETURNING
        VALUE(rs_icon) TYPE ty_icon.

    CLASS-METHODS icon
      IMPORTING
        iv_name        TYPE string
        iv_label       TYPE string OPTIONAL
        iv_fallback    TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    "! Escaped text, with a leading icon (@xx@, @xx\Qtooltip@ or the
    "! converter's @ICON:name) rendered as an icon, as SAP GUI does in
    "! tab, pushbutton and output texts.
    CLASS-METHODS text_html
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    "! The same text without its leading icon, for labels and attributes;
    "! an icon-only text gives the icon's label.
    CLASS-METHODS plain_text
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_entry,
        name   TYPE string,
        code   TYPE string,
        symbol TYPE string,
        tone   TYPE string,
        label  TYPE string,
      END OF ty_entry.

    CLASS-DATA gt_entries TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    CLASS-METHODS tone_color
      IMPORTING
        iv_tone         TYPE string
      RETURNING
        VALUE(rv_color) TYPE string.

    CLASS-METHODS split_text
      IMPORTING
        iv_text    TYPE string
      EXPORTING
        ev_icon    TYPE string
        ev_tooltip TYPE string
        ev_text    TYPE string.
ENDCLASS.

CLASS zcl_gg_host_icons IMPLEMENTATION.

  METHOD class_constructor.
* name is lower case without the icon_ prefix, code is the part between the @ signs.
* Entries without code are semantic aliases and render without tone.
    gt_entries = VALUE #(
* status
      ( name = 'green_light'         code = '08' symbol = 'status-light'      tone = 'success'  label = 'Green light' )
      ( name = 'yellow_light'        code = '09' symbol = 'status-light'      tone = 'warning'  label = 'Yellow light' )
      ( name = 'red_light'           code = '0A' symbol = 'status-light'      tone = 'error'    label = 'Red light' )
      ( name = 'light_out'           code = 'EB' symbol = 'status-light-off'  tone = 'inactive' label = 'Light off' )
      ( name = 'led_green'           code = '5B' symbol = 'status-led'        tone = 'success'  label = 'Green LED' )
      ( name = 'led_yellow'          code = '5D' symbol = 'status-led'        tone = 'warning'  label = 'Yellow LED' )
      ( name = 'led_red'             code = '5C' symbol = 'status-led'        tone = 'error'    label = 'Red LED' )
      ( name = 'led_inactive'        code = 'BZ' symbol = 'status-led'        tone = 'inactive' label = 'Inactive LED' )
      ( name = 'checked'             code = '01' symbol = 'circle-check'      tone = 'success'  label = 'Checked' )
      ( name = 'incomplete'          code = '02' symbol = 'circle-x'          tone = 'error'    label = 'Incomplete' )
      ( name = 'failure'             code = '03' symbol = 'alert-octagon'     tone = 'error'    label = 'Failure' )
      ( name = 'positive'            code = '04' symbol = 'circle-plus'       tone = 'success'  label = 'Positive' )
      ( name = 'negative'            code = '05' symbol = 'circle-minus'      tone = 'error'    label = 'Negative' )
      ( name = 'locked'              code = '06' symbol = 'lock'              tone = ''         label = 'Locked' )
      ( name = 'unlocked'            code = '07' symbol = 'lock-open'         tone = ''         label = 'Unlocked' )
      ( name = 'okay'                code = '0V' symbol = 'circle-check'      tone = 'success'  label = 'Okay' )
      ( name = 'cancel'              code = '0W' symbol = 'x'                 tone = 'error'    label = 'Cancel' )
      ( name = 'information'         code = '0S' symbol = 'info-circle'       tone = 'info'     label = 'Information' )
      ( name = 'warning'             code = 'AH' symbol = 'alert-triangle'    tone = 'warning'  label = 'Warning' )
      ( name = 'message_information' code = '19' symbol = 'info-circle'       tone = 'info'     label = 'Information message' )
      ( name = 'message_warning'     code = '1A' symbol = 'alert-triangle'    tone = 'warning'  label = 'Warning message' )
      ( name = 'message_error'       code = '1B' symbol = 'alert-octagon'     tone = 'error'    label = 'Error message' )
      ( name = 'message_question'    code = '1C' symbol = 'help-circle'       tone = 'info'     label = 'Question' )
      ( name = 'message_critical'    code = '1D' symbol = 'alert-octagon'     tone = 'error'    label = 'Critical message' )
      ( name = 'error_protocol'      code = 'DR' symbol = 'file-alert'        tone = ''         label = 'Error log' )
* functions
      ( name = 'create'              code = '0Y' symbol = 'plus'              tone = ''         label = 'Create' )
      ( name = 'change'              code = '0Z' symbol = 'edit'              tone = ''         label = 'Change' )
      ( name = 'display'             code = '10' symbol = 'eye'               tone = ''         label = 'Display' )
      ( name = 'delete'              code = '11' symbol = 'trash'             tone = ''         label = 'Delete' )
      ( name = 'test'                code = '12' symbol = 'flask'             tone = ''         label = 'Test' )
      ( name = 'copy_object'         code = '14' symbol = 'copy'              tone = ''         label = 'Copy' )
      ( name = 'create_copy'         code = 'EZ' symbol = 'copy-plus'         tone = ''         label = 'Create copy' )
      ( name = 'execute_object'      code = '15' symbol = 'player-play'       tone = ''         label = 'Execute' )
      ( name = 'select_detail'       code = '16' symbol = 'list-search'       tone = ''         label = 'Select detail' )
      ( name = 'insert_row'          code = '17' symbol = 'row-insert-bottom' tone = ''         label = 'Insert row' )
      ( name = 'delete_row'          code = '18' symbol = 'row-remove'        tone = ''         label = 'Delete row' )
      ( name = 'detail'              code = '3R' symbol = 'list-details'      tone = ''         label = 'Detail' )
      ( name = 'toggle_display_change' code = '3I' symbol = 'edit'            tone = ''         label = 'Display/change' )
      ( name = 'display_text'        code = '0P' symbol = 'file-text'         tone = ''         label = 'Display text' )
      ( name = 'change_text'         code = '0Q' symbol = 'file-pencil'       tone = ''         label = 'Change text' )
      ( name = 'select_all'          code = '4B' symbol = 'select-all'        tone = ''         label = 'Select all' )
      ( name = 'deselect_all'        code = '4D' symbol = 'deselect'          tone = ''         label = 'Deselect all' )
      ( name = 'filter'              code = '4G' symbol = 'filter'            tone = ''         label = 'Filter' )
      ( name = 'filter_undo'         code = 'GD' symbol = 'filter-off'        tone = ''         label = 'Remove filter' )
      ( name = 'set_sum'             code = '8B' symbol = 'sum'               tone = ''         label = 'Total' )
      ( name = 'export'              code = '49' symbol = 'file-export'       tone = ''         label = 'Export' )
      ( name = 'import'              code = '48' symbol = 'file-import'       tone = ''         label = 'Import' )
      ( name = 'xls'                 code = 'J2' symbol = 'file-spreadsheet'  tone = ''         label = 'Spreadsheet' )
      ( name = 'pdf'                 code = 'IT' symbol = 'file-type-pdf'     tone = ''         label = 'PDF' )
      ( name = 'print'               code = '0X' symbol = 'printer'           tone = ''         label = 'Print' )
      ( name = 'refresh'             code = '42' symbol = 'refresh'           tone = ''         label = 'Refresh' )
      ( name = 'check'               code = '38' symbol = 'checks'            tone = ''         label = 'Check' )
      ( name = 'generate'            code = '39' symbol = 'wand'              tone = ''         label = 'Generate' )
      ( name = 'activate'            code = '3C' symbol = 'bolt'              tone = ''         label = 'Activate' )
      ( name = 'search_next'         code = '4E' symbol = 'search-plus'       tone = ''         label = 'Find next' )
      ( name = 'previous_object'     code = '2R' symbol = 'chevron-left'      tone = ''         label = 'Previous object' )
      ( name = 'next_object'         code = '2S' symbol = 'chevron-right'     tone = ''         label = 'Next object' )
      ( name = 'page_left'           code = '0G' symbol = 'chevron-left'      tone = ''         label = 'Page left' )
      ( name = 'page_right'          code = '0F' symbol = 'chevron-right'     tone = ''         label = 'Page right' )
      ( name = 'expand'              code = '3S' symbol = 'chevron-down'      tone = ''         label = 'Expand' )
      ( name = 'collapse'            code = '3T' symbol = 'chevron-up'        tone = ''         label = 'Collapse' )
      ( name = 'calculation'         code = '0M' symbol = 'calculator'        tone = ''         label = 'Calculation' )
      ( name = 'graphics'            code = '0N' symbol = 'chart-bar'         tone = ''         label = 'Graphics' )
* system toolbar
      ( name = 'system_okay'         code = '2K' symbol = 'check'             tone = 'success'  label = 'Enter' )
      ( name = 'system_save'         code = '2L' symbol = 'device-floppy'     tone = ''         label = 'Save' )
      ( name = 'system_back'         code = '2M' symbol = 'arrow-left'        tone = ''         label = 'Back' )
      ( name = 'system_end'          code = '2N' symbol = 'logout'            tone = ''         label = 'Exit' )
      ( name = 'system_cancel'       code = '2O' symbol = 'circle-x'          tone = ''         label = 'Cancel' )
      ( name = 'system_copy'         code = '2U' symbol = 'copy'              tone = ''         label = 'Copy' )
      ( name = 'system_paste'        code = '2V' symbol = 'clipboard'         tone = ''         label = 'Paste' )
      ( name = 'system_undo'         code = '2W' symbol = 'arrow-back-up'     tone = ''         label = 'Undo' )
      ( name = 'system_help'         code = '35' symbol = 'help-circle'       tone = ''         label = 'Help' )
      ( name = 'system_favorites'    code = '6D' symbol = 'star'              tone = ''         label = 'Favorites' )
* objects
      ( name = 'closed_folder'       code = 'FN' symbol = 'folder'            tone = ''         label = 'Folder' )
      ( name = 'open_folder'         code = 'FO' symbol = 'folder-open'       tone = ''         label = 'Open folder' )
      ( name = 'folder'              code = 'IH' symbol = 'folder'            tone = ''         label = 'Folder' )
      ( name = 'document'            code = 'AR' symbol = 'file'              tone = ''         label = 'Document' )
      ( name = 'list'                code = '3W' symbol = 'list'              tone = ''         label = 'List' )
      ( name = 'tree'                code = '3M' symbol = 'binary-tree'       tone = ''         label = 'Tree' )
      ( name = 'position'            code = '3Y' symbol = 'map-pin'           tone = ''         label = 'Position' )
      ( name = 'attachment'          code = 'FM' symbol = 'paperclip'         tone = ''         label = 'Attachment' )
      ( name = 'mail'                code = '1S' symbol = 'mail'              tone = ''         label = 'Mail' )
      ( name = 'date'                code = '1U' symbol = 'calendar'          tone = ''         label = 'Date' )
      ( name = 'time'                code = '1T' symbol = 'clock'             tone = ''         label = 'Time' )
      ( name = 'history'             code = '96' symbol = 'history'           tone = ''         label = 'History' )
      ( name = 'employee'            code = '5W' symbol = 'user'              tone = ''         label = 'Employee' )
      ( name = 'settings'            code = 'XC' symbol = 'settings'          tone = ''         label = 'Settings' )
      ( name = 'tools'               code = '45' symbol = 'tool'              tone = ''         label = 'Tools' )
      ( name = 'transport'           code = '4A' symbol = 'truck'             tone = ''         label = 'Transport' )
      ( name = 'background_job'      code = 'M4' symbol = 'clock-play'        tone = ''         label = 'Background job' )
      ( name = 'database_table'      code = 'PO' symbol = 'table'             tone = ''         label = 'Database table' )
* logistics and business objects, named and described as in the SAP ICON table
      ( name = 'object_folder'       code = 'FP' symbol = 'folder-open'       tone = ''         label = 'Open object folder' )
      ( name = 'other_object'        code = '2Q' symbol = 'box'               tone = ''         label = 'Other object' )
      ( name = 'order'               code = '9Z' symbol = 'clipboard-list'    tone = ''         label = 'Order' )
      ( name = 'action_fault'        code = '9O' symbol = 'file-alert'        tone = 'error'    label = 'Request contains errors' )
      ( name = 'ben_offer_open'      code = '9F' symbol = 'tag'               tone = ''         label = 'Open offer' )
      ( name = 'transport_point'     code = 'A5' symbol = 'arrows-exchange'   tone = ''         label = 'Stock transfer point' )
      ( name = 'store_location'      code = 'AC' symbol = 'building-warehouse' tone = ''         label = 'Storage location' )
      ( name = 'supplier'            code = 'AD' symbol = 'building-factory-2' tone = ''         label = 'Vendor' )
      ( name = 'material_revision'   code = 'AT' symbol = 'versions'          tone = ''         label = 'Article revision' )
      ( name = 'retail_product'      code = 'TT' symbol = 'shopping-bag'      tone = ''         label = 'Retail product' )
      ( name = 'dummy'               code = '00' symbol = 'blank'             tone = ''         label = '' )
      ( name = 'space'               code = '5F' symbol = 'blank'             tone = ''         label = '' )
* ICON_* names without a code in the open-abap icon type pool
      ( name = 'execute'             symbol = 'player-play'       label = 'Execute' )
      ( name = 'back'                symbol = 'arrow-left'        label = 'Back' )
      ( name = 'forward'             symbol = 'arrow-right'       label = 'Forward' )
      ( name = 'exit'                symbol = 'logout'            label = 'Exit' )
      ( name = 'save'                symbol = 'device-floppy'     label = 'Save' )
      ( name = 'undo'                symbol = 'arrow-back-up'     label = 'Undo' )
      ( name = 'redo'                symbol = 'arrow-forward-up'  label = 'Redo' )
      ( name = 'find'                symbol = 'search'            label = 'Find' )
      ( name = 'find_more'           symbol = 'binoculars'        label = 'Find more' )
      ( name = 'find_next'           symbol = 'search-plus'       label = 'Find next' )
      ( name = 'help'                symbol = 'help-circle'       label = 'Help' )
      ( name = 'favorite'            symbol = 'star'              label = 'Favorite' )
      ( name = 'program'             symbol = 'file-code'         label = 'Program' )
      ( name = 'database'            symbol = 'database'          label = 'Database' )
      ( name = 'screen'              symbol = 'device-desktop'    label = 'Screen' )
* semantic aliases
      ( name = 'go'                  symbol = 'player-play' )
      ( name = 'search'              symbol = 'search' )
      ( name = 'find-more'           symbol = 'binoculars' )
      ( name = 'find-next'           symbol = 'search-plus' )
      ( name = 'binoculars-plus'     symbol = 'search-plus' )
      ( name = 'first-page'          symbol = 'arrow-bar-to-up' )
      ( name = 'previous-page'       symbol = 'file-arrow-up' )
      ( name = 'next-page'           symbol = 'file-arrow-down' )
      ( name = 'last-page'           symbol = 'arrow-bar-to-down' )
      ( name = 'logout'              symbol = 'logout' )
      ( name = 'edit'                symbol = 'edit' )
      ( name = 'success'             symbol = 'circle-check' )
      ( name = 'error'               symbol = 'circle-x' )
      ( name = 'unknown'             symbol = 'square-dashed' ) ).
  ENDMETHOD.

  METHOD refresh_svg.
    rv_html = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4" /><path d="M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4" /></svg>'.
  ENDMETHOD.

  METHOD sprite.
    rv_html = '<svg class="wb-icon-sprite" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg">' &&
      '<symbol id="wb-icon-player-play" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4v16l13 -8l-13 -8" /></symbol>' &&
      '<symbol id="wb-icon-arrow-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l14 0" /><path d="M5 12l6 6" /><path d="M5 12l6 -6" /></symbol>' &&
      '<symbol id="wb-icon-arrow-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l14 0" /><path d="M13 18l6 -6" /><path d="M13 6l6 6" /></symbol>' &&
      '<symbol id="wb-icon-logout" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 8v-2a2 2 0 0 0 -2 -2h-5a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h5a2 2 0 0 0 2 -2v-2" /><path d="M9 12h12" /><path d="M18 9l3 3l-3 3" /></symbol>' &&
      '<symbol id="wb-icon-device-floppy" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 4h10l4 4v10a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2" /><path d="M10 14a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M14 4l0 4l-6 0l0 -4" /></symbol>' &&
      '<symbol id="wb-icon-arrow-back-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 14l-4 -4l4 -4" /><path d="M5 10h11a4 4 0 1 1 0 8h-1" /></symbol>' &&
      '<symbol id="wb-icon-arrow-forward-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 14l4 -4l-4 -4" /><path d="M19 10h-11a4 4 0 1 0 0 8h1" /></symbol>' &&
      '<symbol id="wb-icon-printer" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 17h2a2 2 0 0 0 2 -2v-4a2 2 0 0 0 -2 -2h-14a2 2 0 0 0 -2 2v4a2 2 0 0 0 2 2h2" /><path d="M17 9v-4a2 2 0 0 0 -2 -2h-6a2 2 0 0 0 -2 2v4" /><path d="M7 15a2 2 0 0 1 2 -2h6a2 2 0 0 1 2 2v4a2 2 0 0 1 -2 2h-6a2 2 0 0 1 -2 -2l0 -4" /></symbol>' &&
      '<symbol id="wb-icon-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" /></symbol>' &&
      '<symbol id="wb-icon-binoculars" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M14 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M16.346 9.17l-.729 -1.261c-.16 -.248 -1.056 -.203 -1.117 .091l-.177 1.38" /><path d="M19.761 14.813l-2.84 -5.133c-.189 -.31 -.592 -.68 -1.421 -.68c-.828 0 -1.5 .448 -1.5 1v6" /><path d="M7.654 9.17l.729 -1.261c.16 -.249 1.056 -.203 1.117 .091l.177 1.38" /><path d="M4.239 14.813l2.84 -5.133c.189 -.31 .592 -.68 1.421 -.68c.828 0 1.5 .448 1.5 1v6" /><path d="M10 12h4v2h-4l0 -2" /></symbol>' &&
      '<symbol id="wb-icon-binoculars-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M14 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M16.346 9.17l-.729 -1.261c-.16 -.248 -1.056 -.203 -1.117 .091l-.177 1.38" /><path d="M19.761 14.813l-2.84 -5.133c-.189 -.31 -.592 -.68 -1.421 -.68c-.828 0 -1.5 .448 -1.5 1v6" /><path d="M7.654 9.17l.729 -1.261c.16 -.249 1.056 -.203 1.117 .091l.177 1.38" /><path d="M4.239 14.813l2.84 -5.133c-.189 -.31 -.592 -.68 -1.421 -.68c-.828 0 -1.5 .448 -1.5 1v6" /><path d="M10 12h4v2h-4l0 -2" /><path d="M20 3v4" /><path d="M18 5h4" /></symbol>' &&
      '<symbol id="wb-icon-help-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M12 16v.01" /><path d="M12 13a2 2 0 0 0 .914 -3.782a1.98 1.98 0 0 0 -2.414 .483" /></symbol>' &&
      '<symbol id="wb-icon-arrow-bar-to-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16" /><path d="M12 20v-12" /><path d="M7 13l5 -5l5 5" /></symbol>' &&
      '<symbol id="wb-icon-arrow-bar-to-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16" /><path d="M12 4v12" /><path d="M7 11l5 5l5 -5" /></symbol>' &&
      '<symbol id="wb-icon-file-arrow-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M12 17v-6" /><path d="M9 14l3 -3l3 3" /></symbol>' &&
      '<symbol id="wb-icon-file-arrow-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M12 11v6" /><path d="M9 14l3 3l3 -3" /></symbol>' &&
      '<symbol id="wb-icon-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5l0 14" /><path d="M5 12l14 0" /></symbol>' &&
      '<symbol id="wb-icon-folder" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 4h4l3 3h7a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2" /></symbol>' &&
      '<symbol id="wb-icon-folder-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 19l2.757 -7.351a1 1 0 0 1 .936 -.649h12.307a1 1 0 0 1 .986 1.164l-.996 5.211a2 2 0 0 1 -1.964 1.625h-14.026a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v2" /></symbol>' &&
      '<symbol id="wb-icon-file-code" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M10 13l-1 2l1 2" /><path d="M14 13l1 2l-1 2" /></symbol>' &&
      '<symbol id="wb-icon-star" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 17.75l-6.172 3.245l1.179 -6.873l-5 -4.867l6.9 -1l3.086 -6.253l3.086 6.253l6.9 1l-5 4.867l1.179 6.873l-6.158 -3.245" /></symbol>' &&
      '<symbol id="wb-icon-device-desktop" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a1 1 0 0 1 1 -1h16a1 1 0 0 1 1 1v10a1 1 0 0 1 -1 1h-16a1 1 0 0 1 -1 -1v-10" /><path d="M7 20h10" /><path d="M9 16v4" /><path d="M15 16v4" /></symbol>' &&
      '<symbol id="wb-icon-database" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a8 3 0 1 0 16 0a8 3 0 1 0 -16 0" /><path d="M4 6v6a8 3 0 0 0 16 0v-6" /><path d="M4 12v6a8 3 0 0 0 16 0v-6" /></symbol>' &&
      '<symbol id="wb-icon-refresh" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4" /><path d="M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4" /></symbol>' &&
      '<symbol id="wb-icon-edit" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h-1a2 2 0 0 0 -2 2v9a2 2 0 0 0 2 2h9a2 2 0 0 0 2 -2v-1" /><path d="M20.385 6.585a2.1 2.1 0 0 0 -2.97 -2.97l-8.415 8.385v3h3l8.385 -8.415" /><path d="M16 5l3 3" /></symbol>' &&
      '<symbol id="wb-icon-circle-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M9 12l2 2l4 -4" /></symbol>' &&
      '<symbol id="wb-icon-circle-x" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M10 10l4 4m0 -4l-4 4" /></symbol>' &&
      '<symbol id="wb-icon-alert-triangle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 9v4" /><path d="M10.363 3.591l-8.106 13.534a1.914 1.914 0 0 0 1.636 2.871h16.214a1.914 1.914 0 0 0 1.636 -2.87l-8.106 -13.536a1.914 1.914 0 0 0 -3.274 0" /><path d="M12 16h.01" /></symbol>' &&
      '<symbol id="wb-icon-info-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M12 9h.01" /><path d="M11 12h1v4h1" /></symbol>' &&
      '<symbol id="wb-icon-trash" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7l16 0" /><path d="M10 11l0 6" /><path d="M14 11l0 6" /><path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" /><path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></symbol>' &&
      '<symbol id="wb-icon-search-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" /><path d="M19 3v4" /><path d="M17 5h4" /></symbol>' &&
      '<symbol id="wb-icon-eye" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 12a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M21 12c-2.4 4 -5.4 6 -9 6c-3.6 0 -6.6 -2 -9 -6c2.4 -4 5.4 -6 9 -6c3.6 0 6.6 2 9 6" /></symbol>' &&
      '<symbol id="wb-icon-copy" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 9.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667l0 -8.666" /><path d="M4.012 16.737a2.005 2.005 0 0 1 -1.012 -1.737v-10c0 -1.1 .9 -2 2 -2h10c.75 0 1.158 .385 1.5 1" /></symbol>' &&
      '<symbol id="wb-icon-copy-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 9.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667l0 -8.666" /><path d="M4.012 16.737a2 2 0 0 1 -1.012 -1.737v-10c0 -1.1 .9 -2 2 -2h10c.75 0 1.158 .385 1.5 1" /><path d="M11 14h6" /><path d="M14 11v6" /></symbol>' &&
      '<symbol id="wb-icon-row-insert-bottom" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6v4a1 1 0 0 1 -1 1h-14a1 1 0 0 1 -1 -1v-4a1 1 0 0 1 1 -1h14a1 1 0 0 1 1 1" /><path d="M12 15l0 4" /><path d="M14 17l-4 0" /></symbol>' &&
      '<symbol id="wb-icon-row-remove" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6v4a1 1 0 0 1 -1 1h-14a1 1 0 0 1 -1 -1v-4a1 1 0 0 1 1 -1h14a1 1 0 0 1 1 1" /><path d="M10 16l4 4" /><path d="M10 20l4 -4" /></symbol>' &&
      '<symbol id="wb-icon-select-all" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 9a1 1 0 0 1 1 -1h6a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-6a1 1 0 0 1 -1 -1l0 -6" /><path d="M12 20v.01" /><path d="M16 20v.01" /><path d="M8 20v.01" /><path d="M4 20v.01" /><path d="M4 16v.01" /><path d="M4 12v.01" /><path d="M4 8v.01" /><path d="M4 4v.01" /><path d="M8 4v.01" /><path d="M12 4v.01" /><path d="M16 4v.01" /><path d="M20 4v.01" /><path d="M20 8v.01" /><path d="M20 12v.01" /><path d="M20 16v.01" /><path d="M20 20v.01" /></symbol>' &&
      '<symbol id="wb-icon-deselect" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 8h3a1 1 0 0 1 1 1v3" /><path d="M16 16h-7a1 1 0 0 1 -1 -1v-7" /><path d="M12 20v.01" /><path d="M16 20v.01" /><path d="M8 20v.01" /><path d="M4 20v.01" /><path d="M4 16v.01" /><path d="M4 12v.01" /><path d="M4 8v.01" /><path d="M8 4v.01" /><path d="M12 4v.01" /><path d="M16 4v.01" /><path d="M20 4v.01" /><path d="M20 8v.01" /><path d="M20 12v.01" /><path d="M20 16v.01" /><path d="M3 3l18 18" /></symbol>' &&
      '<symbol id="wb-icon-filter" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16v2.172a2 2 0 0 1 -.586 1.414l-4.414 4.414v7l-6 2v-8.5l-4.48 -4.928a2 2 0 0 1 -.52 -1.345v-2.227" /></symbol>' &&
      '<symbol id="wb-icon-filter-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 4h12v2.172a2 2 0 0 1 -.586 1.414l-3.914 3.914m-.5 3.5v4l-6 2v-8.5l-4.48 -4.928a2 2 0 0 1 -.52 -1.345v-2.227" /><path d="M3 3l18 18" /></symbol>' &&
      '<symbol id="wb-icon-sum" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 16v2a1 1 0 0 1 -1 1h-11l6 -7l-6 -7h11a1 1 0 0 1 1 1v2" /></symbol>' &&
      '<symbol id="wb-icon-list-details" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 5h8" /><path d="M13 9h5" /><path d="M13 15h8" /><path d="M13 19h5" /><path d="M3 5a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4" /><path d="M3 15a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4" /></symbol>' &&
      '<symbol id="wb-icon-list-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 15a4 4 0 1 0 8 0a4 4 0 1 0 -8 0" /><path d="M18.5 18.5l2.5 2.5" /><path d="M4 6h16" /><path d="M4 12h4" /><path d="M4 18h4" /></symbol>' &&
      '<symbol id="wb-icon-file-export" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M11.5 21h-4.5a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v5m-5 6h7m-3 -3l3 3l-3 3" /></symbol>' &&
      '<symbol id="wb-icon-file-import" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M5 13v-8a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2h-5.5m-9.5 -2h7m-3 -3l3 3l-3 3" /></symbol>' &&
      '<symbol id="wb-icon-file-spreadsheet" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M8 11h8v7h-8l0 -7" /><path d="M8 15h8" /><path d="M11 11v7" /></symbol>' &&
      '<symbol id="wb-icon-file-type-pdf" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4" /><path d="M5 18h1.5a1.5 1.5 0 0 0 0 -3h-1.5v6" /><path d="M17 18h2" /><path d="M20 15h-3v6" /><path d="M11 15v6h1a2 2 0 0 0 2 -2v-2a2 2 0 0 0 -2 -2h-1" /></symbol>' &&
      '<symbol id="wb-icon-checks" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 12l5 5l10 -10" /><path d="M2 12l5 5m5 -5l5 -5" /></symbol>' &&
      '<symbol id="wb-icon-bolt" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 3l0 7l6 0l-8 11l0 -7l-6 0l8 -11" /></symbol>' &&
      '<symbol id="wb-icon-flask" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 3l6 0" /><path d="M10 9l4 0" /><path d="M10 3v6l-4 11a.7 .7 0 0 0 .5 1h11a.7 .7 0 0 0 .5 -1l-4 -11v-6" /></symbol>' &&
      '<symbol id="wb-icon-wand" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 21l15 -15l-3 -3l-15 15l3 3" /><path d="M15 6l3 3" /><path d="M9 3a2 2 0 0 0 2 2a2 2 0 0 0 -2 2a2 2 0 0 0 -2 -2a2 2 0 0 0 2 -2" /><path d="M19 13a2 2 0 0 0 2 2a2 2 0 0 0 -2 2a2 2 0 0 0 -2 -2a2 2 0 0 0 2 -2" /></symbol>' &&
      '<symbol id="wb-icon-chevron-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 6l-6 6l6 6" /></symbol>' &&
      '<symbol id="wb-icon-chevron-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6l-6 6" /></symbol>' &&
      '<symbol id="wb-icon-chevron-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9l6 6l6 -6" /></symbol>' &&
      '<symbol id="wb-icon-chevron-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 15l6 -6l6 6" /></symbol>' &&
      '<symbol id="wb-icon-clipboard" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /></symbol>' &&
      '<symbol id="wb-icon-file-text" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M9 9l1 0" /><path d="M9 13l6 0" /><path d="M9 17l6 0" /></symbol>' &&
      '<symbol id="wb-icon-file-pencil" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M10 18l5 -5a1.414 1.414 0 0 0 -2 -2l-5 5v2h2" /></symbol>' &&
      '<symbol id="wb-icon-calculator" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2l0 -14" /><path d="M8 8a1 1 0 0 1 1 -1h6a1 1 0 0 1 1 1v1a1 1 0 0 1 -1 1h-6a1 1 0 0 1 -1 -1l0 -1" /><path d="M8 14l0 .01" /><path d="M12 14l0 .01" /><path d="M16 14l0 .01" /><path d="M8 17l0 .01" /><path d="M12 17l0 .01" /><path d="M16 17l0 .01" /></symbol>' &&
      '<symbol id="wb-icon-chart-bar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 13a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -6" /><path d="M15 9a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v10a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -10" /><path d="M9 5a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -14" /><path d="M4 20h14" /></symbol>' &&
      '<symbol id="wb-icon-file" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /></symbol>' &&
      '<symbol id="wb-icon-list" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l11 0" /><path d="M9 12l11 0" /><path d="M9 18l11 0" /><path d="M5 6l0 .01" /><path d="M5 12l0 .01" /><path d="M5 18l0 .01" /></symbol>' &&
      '<symbol id="wb-icon-binary-tree" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 20a2 2 0 1 0 -4 0a2 2 0 0 0 4 0" /><path d="M16 4a2 2 0 1 0 -4 0a2 2 0 0 0 4 0" /><path d="M16 20a2 2 0 1 0 -4 0a2 2 0 0 0 4 0" /><path d="M11 12a2 2 0 1 0 -4 0a2 2 0 0 0 4 0" /><path d="M21 12a2 2 0 1 0 -4 0a2 2 0 0 0 4 0" /><path d="M5.058 18.306l2.88 -4.606" /><path d="M10.061 10.303l2.877 -4.604" /><path d="M10.065 13.705l2.876 4.6" /><path d="M15.063 5.7l2.881 4.61" /></symbol>' &&
      '<symbol id="wb-icon-map-pin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /><path d="M17.657 16.657l-4.243 4.243a2 2 0 0 1 -2.827 0l-4.244 -4.243a8 8 0 1 1 11.314 0" /></symbol>' &&
      '<symbol id="wb-icon-paperclip" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 7l-6.5 6.5a1.5 1.5 0 0 0 3 3l6.5 -6.5a3 3 0 0 0 -6 -6l-6.5 6.5a4.5 4.5 0 0 0 9 9l6.5 -6.5" /></symbol>' &&
      '<symbol id="wb-icon-mail" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-10" /><path d="M3 7l9 6l9 -6" /></symbol>' &&
      '<symbol id="wb-icon-calendar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12" /><path d="M16 3v4" /><path d="M8 3v4" /><path d="M4 11h16" /><path d="M11 15h1" /><path d="M12 15v3" /></symbol>' &&
      '<symbol id="wb-icon-clock" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M12 7v5l3 3" /></symbol>' &&
      '<symbol id="wb-icon-history" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 8l0 4l2 2" /><path d="M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5" /></symbol>' &&
      '<symbol id="wb-icon-user" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" /></symbol>' &&
      '<symbol id="wb-icon-settings" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065" /><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /></symbol>' &&
      '<symbol id="wb-icon-tool" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 10h3v-3l-3.5 -3.5a6 6 0 0 1 8 8l6 6a2 2 0 0 1 -3 3l-6 -6a6 6 0 0 1 -8 -8l3.5 3.5" /></symbol>' &&
      '<symbol id="wb-icon-truck" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M15 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M5 17h-2v-11a1 1 0 0 1 1 -1h9v12m-4 0h6m4 0h2v-6h-8m0 -5h5l3 5" /></symbol>' &&
      '<symbol id="wb-icon-clock-play" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 7v5l2 2" /><path d="M17 22l5 -3l-5 -3l0 6" /><path d="M13.017 20.943a9 9 0 1 1 7.831 -7.292" /></symbol>' &&
      '<symbol id="wb-icon-table" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14" /><path d="M3 10h18" /><path d="M10 3v18" /></symbol>' &&
      '<symbol id="wb-icon-lock" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 13a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-6" /><path d="M11 16a1 1 0 1 0 2 0a1 1 0 0 0 -2 0" /><path d="M8 11v-4a4 4 0 1 1 8 0v4" /></symbol>' &&
      '<symbol id="wb-icon-lock-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 13a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2l0 -6" /><path d="M11 16a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M8 11v-5a4 4 0 0 1 8 0" /></symbol>' &&
      '<symbol id="wb-icon-circle-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M9 12h6" /><path d="M12 9v6" /></symbol>' &&
      '<symbol id="wb-icon-circle-minus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M9 12l6 0" /></symbol>' &&
      '<symbol id="wb-icon-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5l10 -10" /></symbol>' &&
      '<symbol id="wb-icon-x" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6l-12 12" /><path d="M6 6l12 12" /></symbol>' &&
      '<symbol id="wb-icon-alert-octagon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12.802 2.165l5.575 2.389c.48 .206 .863 .589 1.07 1.07l2.388 5.574c.22 .512 .22 1.092 0 1.604l-2.389 5.575c-.206 .48 -.589 .863 -1.07 1.07l-5.574 2.388c-.512 .22 -1.092 .22 -1.604 0l-5.575 -2.389a2.036 2.036 0 0 1 -1.07 -1.07l-2.388 -5.574a2.036 2.036 0 0 1 0 -1.604l2.389 -5.575c.206 -.48 .589 -.863 1.07 -1.07l5.574 -2.388a2.036 2.036 0 0 1 1.604 0" /><path d="M12 8v4" /><path d="M12 16h.01" /></symbol>' &&
      '<symbol id="wb-icon-file-alert" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M12 17l.01 0" /><path d="M12 11l0 3" /></symbol>' &&
      '<symbol id="wb-icon-square-dashed" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2l0 -14" /></symbol>' &&
      '<symbol id="wb-icon-status-light" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.5" stroke-opacity=".45" /><circle cx="12" cy="12" r="6.5" fill="currentColor" stroke="none" /></symbol>' &&
      '<symbol id="wb-icon-status-light-off" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.5" stroke-opacity=".45" /><circle cx="12" cy="12" r="6.5" fill="none" stroke="currentColor" stroke-width="1.5" /></symbol>' &&
      '<symbol id="wb-icon-status-led" viewBox="0 0 24 24"><rect x="6" y="6" width="12" height="12" rx="3" fill="currentColor" stroke="none" /></symbol>' &&
      '<symbol id="wb-icon-blank" viewBox="0 0 24 24"></symbol>' &&
      '<symbol id="wb-icon-box" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l8 4.5l0 9l-8 4.5l-8 -4.5l0 -9l8 -4.5" /><path d="M12 12l8 -4.5" /><path d="M12 12l0 9" /><path d="M12 12l-8 -4.5" /></symbol>' &&
      '<symbol id="wb-icon-clipboard-list" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /><path d="M9 12l.01 0" /><path d="M13 12l2 0" /><path d="M9 16l.01 0" /><path d="M13 16l2 0" /></symbol>' &&
      '<symbol id="wb-icon-tag" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6.5 7.5a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M3 6v5.172a2 2 0 0 0 .586 1.414l7.71 7.71a2.41 2.41 0 0 0 3.408 0l5.592 -5.592a2.41 2.41 0 0 0 0 -3.408l-7.71 -7.71a2 2 0 0 0 -1.414 -.586h-5.172a3 3 0 0 0 -3 3" /></symbol>' &&
      '<symbol id="wb-icon-arrows-exchange" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 10h14l-4 -4" /><path d="M17 14h-14l4 4" /></symbol>' &&
      '<symbol id="wb-icon-building-warehouse" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21v-13l9 -4l9 4v13" /><path d="M13 13h4v8h-10v-6h6" /><path d="M13 21v-9a1 1 0 0 0 -1 -1h-2a1 1 0 0 0 -1 1v3" /></symbol>' &&
      '<symbol id="wb-icon-building-factory-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18" /><path d="M5 21v-12l5 4v-4l5 4h4" /><path d="M19 21v-8l-1.436 -9.574a.5 .5 0 0 0 -.495 -.426h-1.145a.5 .5 0 0 0 -.494 .418l-1.43 8.582" /><path d="M9 17h1" /><path d="M14 17h1" /></symbol>' &&
      '<symbol id="wb-icon-versions" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 7a2 2 0 0 1 2 -2h6a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-6a2 2 0 0 1 -2 -2l0 -10" /><path d="M7 7l0 10" /><path d="M4 8l0 8" /></symbol>' &&
      '<symbol id="wb-icon-shopping-bag" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6.331 8h11.339a2 2 0 0 1 1.977 2.304l-1.255 8.152a3 3 0 0 1 -2.966 2.544h-6.852a3 3 0 0 1 -2.965 -2.544l-1.255 -8.152a2 2 0 0 1 1.977 -2.304" /><path d="M9 11v-5a3 3 0 0 1 6 0v5" /></symbol>' &&
      '</svg>'.
  ENDMETHOD.

  METHOD resolve.
    DATA lv_value TYPE string.
    DATA lv_tooltip TYPE string.
    DATA lv_code TYPE string.
    DATA lv_wrapped TYPE abap_bool.
    DATA ls_entry TYPE ty_entry.

    lv_value = condense( iv_name ).
    lv_wrapped = xsdbool( lv_value CP '@*' ).
    SPLIT lv_value AT '\Q' INTO lv_value lv_tooltip.
    REPLACE ALL OCCURRENCES OF '@' IN lv_value WITH ``.
    REPLACE ALL OCCURRENCES OF '@' IN lv_tooltip WITH ``.
    TRANSLATE lv_value TO LOWER CASE.
    IF lv_value CP 'icon_*'.
      lv_value = substring( val = lv_value
                            off = 5 ).
    ENDIF.
    lv_code = to_upper( lv_value ).

    IF lv_wrapped = abap_true AND strlen( lv_value ) = 2.
      READ TABLE gt_entries INTO ls_entry WITH KEY code = lv_code.
    ENDIF.
    IF ls_entry IS INITIAL.
      READ TABLE gt_entries INTO ls_entry WITH KEY name = lv_value.
    ENDIF.
    IF ls_entry IS INITIAL.
      READ TABLE gt_entries INTO ls_entry WITH KEY symbol = lv_value.
      CLEAR ls_entry-tone.
      CLEAR ls_entry-label.
    ENDIF.
    IF ls_entry-symbol IS INITIAL AND strlen( lv_value ) = 2.
      READ TABLE gt_entries INTO ls_entry WITH KEY code = lv_code.
    ENDIF.

    rs_icon-symbol = ls_entry-symbol.
    rs_icon-tone = ls_entry-tone.
    rs_icon-label = COND #( WHEN lv_tooltip IS NOT INITIAL THEN lv_tooltip ELSE ls_entry-label ).
  ENDMETHOD.

  METHOD icon.
    DATA ls_icon TYPE ty_icon.
    DATA lv_class TYPE string.
    DATA lv_style TYPE string.

    ls_icon = resolve( iv_name ).
    IF ls_icon-symbol IS INITIAL AND iv_fallback IS NOT INITIAL.
      ls_icon = resolve( iv_fallback ).
    ENDIF.
    IF ls_icon-symbol IS INITIAL.
      ls_icon = resolve( 'unknown' ).
    ENDIF.
    IF ls_icon-tone IS NOT INITIAL.
      lv_class = | wb-icon--{ ls_icon-tone }|.
      lv_style = | style="color:{ tone_color( ls_icon-tone ) }"|.
    ENDIF.

    IF iv_label IS INITIAL.
      rv_html = |<svg class="wb-icon{ lv_class }"{ lv_style } aria-hidden="true" focusable="false"><use href="#wb-icon-{ ls_icon-symbol }"></use></svg>|.
    ELSE.
      rv_html = |<svg class="wb-icon{ lv_class }"{ lv_style } role="img" aria-label="{ zcl_gg_host_html=>escape_attribute( iv_label ) }" focusable="false"><use href="#wb-icon-{ ls_icon-symbol }"></use></svg>|.
    ENDIF.
  ENDMETHOD.

  METHOD split_text.
    DATA lv_end TYPE i.

    CLEAR: ev_icon, ev_tooltip.
    ev_text = iv_text.
    IF ev_text CP '@ICON:*'.
      ev_text = substring( val = ev_text
                           off = 6 ).
      SPLIT ev_text AT space INTO ev_icon ev_text.
      ev_icon = |icon_{ ev_icon }|.
    ELSEIF ev_text CP '@++@*' OR ev_text CP '@++\Q*@*'.
      lv_end = find( val = ev_text
                     sub = '@'
                     off = 1 ).
      ev_icon = substring( val = ev_text
                           len = lv_end + 1 ).
      ev_text = substring( val = ev_text
                           off = lv_end + 1 ).
      ev_tooltip = substring_after( val = ev_icon
                                    sub = '\Q' ).
      REPLACE ALL OCCURRENCES OF '@' IN ev_tooltip WITH ``.
    ELSE.
      RETURN.
    ENDIF.
    SHIFT ev_text LEFT DELETING LEADING space.
  ENDMETHOD.

  METHOD plain_text.
    split_text( EXPORTING iv_text = iv_text
                IMPORTING ev_icon = DATA(lv_icon)
                          ev_text = rv_text ).
    IF rv_text IS INITIAL AND lv_icon IS NOT INITIAL.
      DATA(ls_icon) = resolve( lv_icon ).
      rv_text = ls_icon-label.
    ENDIF.
  ENDMETHOD.

  METHOD text_html.
    split_text( EXPORTING iv_text    = iv_text
                IMPORTING ev_icon    = DATA(lv_icon)
                          ev_tooltip = DATA(lv_tooltip)
                          ev_text    = DATA(lv_text) ).
    IF lv_icon IS INITIAL.
      rv_html = zcl_gg_host_html=>escape_text( iv_text ).
      RETURN.
    ENDIF.

    DATA(ls_icon) = resolve( lv_icon ).
    rv_html = icon( iv_name  = lv_icon
                    iv_label = COND #( WHEN lv_text IS INITIAL THEN ls_icon-label ) ).
    IF lv_tooltip IS NOT INITIAL.
      rv_html = |<span title="{ zcl_gg_host_html=>escape_attribute( lv_tooltip ) }">{ rv_html }</span>|.
    ENDIF.
    IF lv_text IS NOT INITIAL.
      rv_html = |{ rv_html } { zcl_gg_host_html=>escape_text( lv_text ) }|.
    ENDIF.
  ENDMETHOD.

  METHOD tone_color.
    CASE iv_tone.
      WHEN 'success'.
        rv_color = '#218342'.
      WHEN 'warning'.
        rv_color = '#c27800'.
      WHEN 'error'.
        rv_color = '#b3261e'.
      WHEN 'info'.
        rv_color = '#0b5cad'.
      WHEN 'inactive'.
        rv_color = '#8a8f98'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
