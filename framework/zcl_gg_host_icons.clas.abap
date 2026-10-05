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

    "! A finished page with only the sprite symbols it refers to, by
    "! #wb-icon-<symbol>. The sprite holds every icon of the ICON type pool;
    "! a page uses a handful of them.
    CLASS-METHODS prune_sprite
      IMPORTING
        iv_html        TYPE string
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
* the rest of the open-abap ICON type pool, labelled with the SAP quick info
      ( name = 'abap'                code = '9U' symbol = 'code'              tone = ''         label = 'ABAP Routine' )
      ( name = 'action_success'      code = '9P' symbol = 'circle-check'      tone = 'success'  label = 'Request successful' )
      ( name = 'active_inactive'     code = '9B' symbol = 'toggle-left'       tone = ''         label = 'Display mode active/inactive' )
      ( name = 'activity'            code = '9Y' symbol = 'activity'          tone = ''         label = 'Activity' )
      ( name = 'add_row'             code = 'XR' symbol = 'row-insert-bottom' tone = ''         label = 'Insert line' )
      ( name = 'address'             code = '0T' symbol = 'address-book'      tone = ''         label = 'Address' )
      ( name = 'adopt'               code = 'IL' symbol = 'file-import'       tone = ''         label = 'Adopt object' )
      ( name = 'alarm'               code = '1V' symbol = 'alarm'             tone = ''         label = 'Alarm' )
      ( name = 'alert'               code = 'AG' symbol = 'bell-ringing'      tone = ''         label = 'Alarm' )
      ( name = 'allow'               code = '8X' symbol = 'thumb-up'          tone = 'success'  label = 'Approve' )
      ( name = 'annotation'          code = '0J' symbol = 'note'              tone = ''         label = 'Note' )
      ( name = 'arrow_left'          code = '9S' symbol = 'arrow-left'        tone = ''         label = 'Arrow left' )
      ( name = 'arrow_right'         code = '9T' symbol = 'arrow-right'       tone = ''         label = 'Arrow right' )
      ( name = 'availability_check'  code = 'FC' symbol = 'calendar-check'    tone = ''         label = 'Check availability' )
      ( name = 'ben_current_benefits' code = '9I' symbol = 'heart-handshake'   tone = ''         label = 'Current benefits' )
      ( name = 'ben_termination'     code = '9J' symbol = 'heart-off'         tone = ''         label = 'Terminate benefits' )
      ( name = 'biw_info_catalog'    code = '6N' symbol = 'book'              tone = ''         label = 'InfoCatalog' )
      ( name = 'biw_info_cube'       code = '6H' symbol = 'cube'              tone = ''         label = 'InfoCube' )
      ( name = 'biw_monitor'         code = '6P' symbol = 'device-desktop-analytics' tone = ''         label = 'Monitor' )
      ( name = 'biw_report'          code = '6T' symbol = 'report-analytics'  tone = ''         label = 'Report' )
      ( name = 'biw_scheduler'       code = '6Q' symbol = 'calendar-time'     tone = ''         label = 'Scheduler' )
      ( name = 'biw_source_sys_r3'   code = '6K' symbol = 'server'            tone = ''         label = 'Source system (R/3 System)' )
      ( name = 'booking_ok'          code = 'B1' symbol = 'circle-check'      tone = 'success'  label = 'Booking OK' )
      ( name = 'booking_stop'        code = 'B2' symbol = 'circle-x'          tone = 'error'    label = 'Cancel Booking' )
      ( name = 'breakpoint'          code = '3U' symbol = 'hand-stop'         tone = ''         label = 'Breakpoint' )
      ( name = 'breakpoint_disable'  code = 'UR' symbol = 'hand-stop'         tone = 'inactive' label = 'Disabled Breakpoint' )
      ( name = 'businav_process'     code = '4S' symbol = 'route'             tone = ''         label = 'Process' )
      ( name = 'businav_processmatrix' code = '4T' symbol = 'table'             tone = ''         label = 'Process Selection Matrix' )
      ( name = 'businav_value_chain' code = '5G' symbol = 'link'              tone = ''         label = 'Value chain' )
      ( name = 'bw_info_cube_ina'    code = 'F4' symbol = 'cube'              tone = 'inactive' label = 'InfoCube, inactive' )
      ( name = 'bw_ra_setting_active' code = 'O1' symbol = 'user-cog'          tone = 'success'  label = 'Reporting agent: Active' )
      ( name = 'bw_ra_setting_inactive' code = 'O2' symbol = 'user-cog'          tone = 'inactive' label = 'Reporting agent: Inactive' )
      ( name = 'checkbox'            code = 'R7' symbol = 'checkbox'          tone = ''         label = 'Checkbox' )
      ( name = 'claim'               code = 'FH' symbol = 'file-invoice'      tone = ''         label = 'Call/define claim file' )
      ( name = 'client_breakpoint'   code = 'VD' symbol = 'hand-stop'         tone = ''         label = 'Session-Specific Breakpoint' )
      ( name = 'close'               code = '3X' symbol = 'x'                 tone = ''         label = 'Close' )
      ( name = 'color'               code = 'G3' symbol = 'palette'           tone = ''         label = 'Color' )
      ( name = 'column_left'         code = '0D' symbol = 'chevron-left'      tone = ''         label = 'Column left' )
      ( name = 'column_right'        code = '0E' symbol = 'chevron-right'     tone = ''         label = 'Column right' )
      ( name = 'compare'             code = '46' symbol = 'arrows-diff'       tone = ''         label = 'Compare' )
      ( name = 'complete'            code = 'DF' symbol = 'circle-check'      tone = 'success'  label = 'Completed' )
      ( name = 'composite_activitygroup' code = 'M7' symbol = 'users-group'       tone = ''         label = 'Composite role' )
      ( name = 'configuration'       code = 'BX' symbol = 'adjustments'       tone = ''         label = 'Configuration' )
      ( name = 'connect'             code = 'GB' symbol = 'plug-connected'    tone = ''         label = 'Connect' )
      ( name = 'connection_object'   code = 'PQ' symbol = 'plug'              tone = ''         label = 'Connection object' )
      ( name = 'convert'             code = '3H' symbol = 'transform'         tone = ''         label = 'Convert' )
      ( name = 'cost_components'     code = 'Q7' symbol = 'chart-pie'         tone = ''         label = 'Cost Components' )
      ( name = 'create_note'         code = '0K' symbol = 'file-plus'         tone = ''         label = 'Create note' )
      ( name = 'create_text'         code = '0O' symbol = 'text-plus'         tone = ''         label = 'Create text' )
      ( name = 'customer'            code = 'A0' symbol = 'user-dollar'       tone = ''         label = 'Customer' )
      ( name = 'customs'             code = 'D7' symbol = 'gavel'             tone = ''         label = 'Legal area -- customs' )
      ( name = 'cut_relation'        code = '53' symbol = 'unlink'            tone = ''         label = 'Cancel link' )
      ( name = 'data_area_collapse'  code = 'K2' symbol = 'layout-navbar-collapse' tone = ''         label = 'Compress data areas' )
      ( name = 'data_area_expand'    code = 'K1' symbol = 'layout-navbar-expand' tone = ''         label = 'Expand data areas' )
      ( name = 'deactivate'          code = '8I' symbol = 'bolt-off'          tone = ''         label = 'Deactivate' )
      ( name = 'defect'              code = 'F1' symbol = 'circle-x'          tone = 'error'    label = 'Not completed' )
      ( name = 'delete_favorites'    code = 'ES' symbol = 'star-off'          tone = ''         label = 'Delete from favorites' )
      ( name = 'delete_template'     code = 'Q0' symbol = 'template-off'      tone = ''         label = 'Reset Template' )
      ( name = 'delivery_inbound'    code = 'PG' symbol = 'truck-delivery'    tone = ''         label = 'Inbound Delivery' )
      ( name = 'delivery_no_confirmation' code = 'PB' symbol = 'player-skip-forward' tone = ''         label = 'Continue without confirming' )
      ( name = 'dimension'           code = '9Q' symbol = 'dimensions'        tone = ''         label = 'Dimension' )
      ( name = 'disconnect'          code = 'GC' symbol = 'plug-connected-x'  tone = ''         label = 'Disconnect' )
      ( name = 'display_more'        code = '1E' symbol = 'arrow-right-circle' tone = 'success'  label = 'Multiple Selection (Active)' )
      ( name = 'display_note'        code = '0L' symbol = 'note'              tone = ''         label = 'Display note' )
      ( name = 'dispo_level'         code = 'A2' symbol = 'stack-2'           tone = ''         label = 'Planning level' )
      ( name = 'doc_header_detail'   code = 'FA' symbol = 'file-description'  tone = ''         label = 'Display doc. header details' )
      ( name = 'dropdownlist'        code = 'R5' symbol = 'select'            tone = ''         label = 'Dropdown Box' )
      ( name = 'edit_file'           code = 'HL' symbol = 'file-pencil'       tone = ''         label = 'Edit file' )
      ( name = 'element'             code = 'HO' symbol = 'circle-dot'        tone = ''         label = 'Data type "Element"' )
      ( name = 'eml'                 code = 'J8' symbol = 'mail'              tone = ''         label = 'Outlook Express Mail' )
      ( name = 'enter_more'          code = '1F' symbol = 'arrow-right-circle' tone = ''         label = 'Multiple selection' )
      ( name = 'envelope_closed'     code = 'E2' symbol = 'mail'              tone = ''         label = 'Unread message' )
      ( name = 'equal'               code = '1G' symbol = 'equal'             tone = ''         label = 'Equals' )
      ( name = 'equal_green'         code = '20' symbol = 'equal'             tone = 'success'  label = 'Select: Equal to' )
      ( name = 'equal_red'           code = '2A' symbol = 'equal'             tone = 'error'    label = 'Do not select: Equal to' )
      ( name = 'extra'               code = 'BU' symbol = 'gift'              tone = ''         label = 'Free goods' )
      ( name = 'fast_entry'          code = 'BQ' symbol = 'keyboard'          tone = ''         label = 'Fast entry' )
      ( name = 'field_with_text'     code = 'OC' symbol = 'forms'             tone = ''         label = 'Field with text' )
      ( name = 'finite'              code = 'CI' symbol = 'gauge'             tone = ''         label = 'Finite capacity' )
      ( name = 'foreign_key'         code = '3V' symbol = 'key'               tone = ''         label = 'Foreign Keys' )
      ( name = 'gis_pan'             code = 'NK' symbol = 'arrows-move'       tone = ''         label = 'Move center of card' )
      ( name = 'gis_promote'         code = 'NM' symbol = 'stack-push'        tone = ''         label = 'Card layer higher' )
      ( name = 'graduate'            code = 'BT' symbol = 'stairs'            tone = ''         label = 'Scales' )
      ( name = 'greater_equal_green' code = '24' symbol = 'math-equal-greater' tone = 'success'  label = 'Select: Greater than/equal to' )
      ( name = 'greater_green'       code = '22' symbol = 'math-greater'      tone = 'success'  label = 'Select: Greater than' )
      ( name = 'header'              code = '3P' symbol = 'layout-navbar'     tone = ''         label = 'Header' )
      ( name = 'helpassistent_on'    code = 'OF' symbol = 'lifebuoy'          tone = ''         label = 'Activate Help Assistant' )
      ( name = 'hint'                code = 'AI' symbol = 'bulb'              tone = ''         label = 'Note' )
      ( name = 'host'                code = 'G6' symbol = 'server-2'          tone = ''         label = 'Computer/Host' )
      ( name = 'hr_position'         code = 'LC' symbol = 'user-square'       tone = ''         label = 'Position with employee' )
      ( name = 'htm'                 code = 'J4' symbol = 'file-type-html'    tone = ''         label = 'HTML Document' )
      ( name = 'icon_list'           code = '3D' symbol = 'icons'             tone = ''         label = 'Icon list' )
      ( name = 'idoc'                code = 'G5' symbol = 'file-database'     tone = ''         label = 'Display IDocs' )
      ( name = 'import_all_requests' code = 'K4' symbol = 'package-import'    tone = ''         label = 'Import' )
      ( name = 'import_transport_request' code = 'K5' symbol = 'file-import'       tone = ''         label = 'Individual import' )
      ( name = 'include_in_selection' code = 'E4' symbol = 'circle-check'      tone = 'success'  label = 'Go' )
      ( name = 'incoming_object'     code = 'LR' symbol = 'file-arrow-right'  tone = ''         label = 'Reassigned object' )
      ( name = 'incompletion_log'    code = 'KK' symbol = 'clipboard-x'       tone = ''         label = 'Log of incomplete items' )
      ( name = 'inspection_characteristic' code = 'GV' symbol = 'ruler-measure'     tone = ''         label = 'Inspection characteristic' )
      ( name = 'inspection_lot'      code = 'EO' symbol = 'zoom-check'        tone = ''         label = 'Inspection lot' )
      ( name = 'inspection_method'   code = 'GS' symbol = 'microscope'        tone = ''         label = 'Check Method' )
      ( name = 'intensify'           code = '4K' symbol = 'highlight'         tone = ''         label = 'Highlight' )
      ( name = 'intensify_critical'  code = 'HC' symbol = 'highlight'         tone = 'warning'  label = 'Highlight critical' )
      ( name = 'intensify_undo'      code = 'GF' symbol = 'highlight-off'     tone = ''         label = 'Undo highlighting' )
      ( name = 'interface'           code = '63' symbol = 'api'               tone = ''         label = 'Interface' )
      ( name = 'interval_include_green' code = '26' symbol = 'arrows-horizontal' tone = 'success'  label = 'Select: Include range' )
      ( name = 'interval_include_red' code = '2G' symbol = 'arrows-horizontal' tone = 'error'    label = 'Do not select: Include range' )
      ( name = 'less_equal_green'    code = '25' symbol = 'math-equal-lower'  tone = 'success'  label = 'Select: Less than/equal to' )
      ( name = 'less_green'          code = '23' symbol = 'math-lower'        tone = 'success'  label = 'Select: Less than' )
      ( name = 'location'            code = 'AF' symbol = 'map-pin'           tone = ''         label = 'Location' )
      ( name = 'mapped_relation'     code = 'EY' symbol = 'arrows-join'       tone = ''         label = 'Display mapping relationships' )
      ( name = 'mass_change'         code = 'HB' symbol = 'pencil-cog'        tone = ''         label = 'Carry Out a Mass Change' )
      ( name = 'mass_change_done'    code = 'XP' symbol = 'pencil-check'      tone = ''         label = 'Mass Change Performed' )
      ( name = 'master_data_act'     code = '6V' symbol = 'database'          tone = ''         label = 'Master Data' )
      ( name = 'material'            code = 'A6' symbol = 'package'           tone = ''         label = 'Article' )
      ( name = 'message_critical_small' code = '8N' symbol = 'alert-octagon'     tone = 'error'    label = 'Critical message' )
      ( name = 'message_error_small' code = '8O' symbol = 'alert-octagon'     tone = 'error'    label = 'Error message' )
      ( name = 'message_information_small' code = '8P' symbol = 'info-circle'       tone = 'info'     label = 'Information message' )
      ( name = 'message_question_small' code = '8Q' symbol = 'help-circle'       tone = 'info'     label = 'Question' )
      ( name = 'message_warning_small' code = '8R' symbol = 'alert-triangle'    tone = 'warning'  label = 'Warning' )
      ( name = 'model'               code = 'A7' symbol = 'schema'            tone = ''         label = 'Model' )
      ( name = 'modification_create' code = '97' symbol = 'pencil-plus'       tone = ''         label = 'Modification: Create, Change' )
      ( name = 'modification_overview' code = '98' symbol = 'list-details'      tone = ''         label = 'Modification: Overview' )
      ( name = 'modify'              code = '61' symbol = 'puzzle'            tone = ''         label = 'Modify' )
      ( name = 'money'               code = 'AZ' symbol = 'coin'              tone = ''         label = 'Price enquiry' )
      ( name = 'move'                code = '40' symbol = 'arrows-move'       tone = ''         label = 'Move' )
      ( name = 'new_task'            code = 'LJ' symbol = 'clipboard-plus'    tone = ''         label = 'Create task' )
      ( name = 'no_status'           code = 'MG' symbol = 'circle-dashed'     tone = 'inactive' label = 'No Status' )
      ( name = 'not_equal_green'     code = '21' symbol = 'equal-not'         tone = 'success'  label = 'Select: Not equal to' )
      ( name = 'not_equal_red'       code = '2B' symbol = 'equal-not'         tone = 'error'    label = 'Do not select: Not equal to' )
      ( name = 'object_list'         code = 'IG' symbol = 'list'              tone = ''         label = 'List' )
      ( name = 'oo_class_event'      code = 'C6' symbol = 'bolt'              tone = ''         label = 'Class event' )
      ( name = 'oo_connection'       code = '7N' symbol = 'link'              tone = ''         label = 'Relations' )
      ( name = 'oo_event'            code = '7K' symbol = 'bolt'              tone = ''         label = 'Event' )
      ( name = 'oo_inst_event'       code = 'C7' symbol = 'bolt'              tone = ''         label = 'Instance Event' )
      ( name = 'oo_object'           code = 'C9' symbol = 'box'               tone = ''         label = 'Object' )
      ( name = 'open'                code = 'JJ' symbol = 'folder-open'       tone = ''         label = 'Open object' )
      ( name = 'operation'           code = '9X' symbol = 'settings-automation' tone = ''         label = 'Operation' )
      ( name = 'org_unit'            code = 'BN' symbol = 'sitemap'           tone = ''         label = 'Organizational Unit' )
      ( name = 'outgoing_object'     code = 'LS' symbol = 'file-minus'        tone = ''         label = 'Delimited object' )
      ( name = 'outgoing_org_unit'   code = 'LH' symbol = 'sitemap-off'       tone = ''         label = 'Limited assignment' )
      ( name = 'overview'            code = '3Q' symbol = 'layout-dashboard'  tone = ''         label = 'Overview' )
      ( name = 'package_application' code = 'QD' symbol = 'package'           tone = ''         label = 'Application packet' )
      ( name = 'package_standard'    code = 'QC' symbol = 'package'           tone = ''         label = 'Standard package' )
      ( name = 'packing'             code = 'E8' symbol = 'package-import'    tone = ''         label = 'Pack' )
      ( name = 'parameter_result'    code = '7B' symbol = 'variable'          tone = ''         label = 'Result parameters' )
      ( name = 'partner'             code = 'DG' symbol = 'users'             tone = ''         label = 'Call partner' )
      ( name = 'patient_smartcard'   code = 'Q2' symbol = 'id'                tone = ''         label = 'Transfer healthcare smartcard' )
      ( name = 'pattern_include_green' code = '28' symbol = 'asterisk'          tone = 'success'  label = 'Select: Include pattern' )
      ( name = 'pattern_include_red' code = '2I' symbol = 'asterisk'          tone = 'error'    label = 'Do not select: Include pattern' )
      ( name = 'pdir_back'           code = 'CF' symbol = 'arrow-back'        tone = ''         label = 'Planning direction backwards' )
      ( name = 'personal_help'       code = '4L' symbol = 'help-circle'       tone = ''         label = 'Individual help' )
      ( name = 'physical_sample'     code = 'GW' symbol = 'test-pipe'         tone = ''         label = 'Physical sample' )
      ( name = 'plant'               code = 'A8' symbol = 'building-factory'  tone = ''         label = 'Site' )
      ( name = 'pm_insert'           code = 'CL' symbol = 'column-insert-right' tone = ''         label = 'Plan. mode insert operation' )
      ( name = 'pm_press'            code = 'CM' symbol = 'arrow-autofit-width' tone = ''         label = 'Plan.mode squeeze in operation' )
      ( name = 'position_hr'         code = 'BI' symbol = 'user-square'       tone = ''         label = 'Position (workplace)' )
      ( name = 'ppe_snode'           code = 'N1' symbol = 'hierarchy-2'       tone = ''         label = 'Structure node with variants' )
      ( name = 'price'               code = 'FD' symbol = 'receipt'           tone = ''         label = 'Pricing conditions' )
      ( name = 'price_analysis'      code = 'Q6' symbol = 'chart-line'        tone = ''         label = 'Article Price Analysis' )
      ( name = 'print_with_parameters' code = 'EW' symbol = 'printer'           tone = ''         label = 'Print with parameters' )
      ( name = 'product_group'       code = 'A9' symbol = 'category'          tone = ''         label = 'Product Group' )
      ( name = 'profit_center'       code = 'D2' symbol = 'building-bank'     tone = ''         label = 'Profit center master record' )
      ( name = 'proshare'            code = '1W' symbol = 'share'             tone = ''         label = 'ProShare' )
      ( name = 'protocol'            code = 'DH' symbol = 'file-text'         tone = ''         label = 'Display log' )
      ( name = 'ps_relationship'     code = 'EH' symbol = 'arrows-join'       tone = ''         label = 'Relationships' )
      ( name = 'ps_wbs_element'      code = 'ED' symbol = 'hierarchy-3'       tone = ''         label = 'WBS Element' )
      ( name = 'qualify'             code = '5Z' symbol = 'certificate'       tone = ''         label = 'Qualify' )
      ( name = 'question'            code = 'B0' symbol = 'message-question'  tone = ''         label = 'Query' )
      ( name = 'read_file'           code = 'HJ' symbol = 'file-search'       tone = ''         label = 'Read file' )
      ( name = 'reference_list'      code = '3A' symbol = 'list-search'       tone = ''         label = 'Where-Used List' )
      ( name = 'reject'              code = '8Y' symbol = 'thumb-down'        tone = 'error'    label = 'Reject' )
      ( name = 'relation'            code = 'BW' symbol = 'affiliate'         tone = ''         label = 'Object Dependencies' )
      ( name = 'relationship'        code = 'AA' symbol = 'affiliate'         tone = ''         label = 'Relationship' )
      ( name = 'release'             code = '5Y' symbol = 'flag'              tone = ''         label = 'Release' )
      ( name = 'remove_from_selection' code = 'GI' symbol = 'circle-x'          tone = 'error'    label = 'Stop' )
      ( name = 'remove_row'          code = 'XQ' symbol = 'row-remove'        tone = ''         label = 'Delete Line' )
      ( name = 'replace'             code = '37' symbol = 'replace'           tone = ''         label = 'Replace' )
      ( name = 'report_template'     code = 'QH' symbol = 'report'            tone = ''         label = 'Formatted Report' )
      ( name = 'resubmission'        code = 'FR' symbol = 'calendar-repeat'   tone = ''         label = 'Resubmit' )
      ( name = 'retail_store'        code = 'TU' symbol = 'building-store'    tone = ''         label = 'Retail Store' )
      ( name = 'sap'                 code = 'KR' symbol = 'world'             tone = ''         label = 'SAP' )
      ( name = 'sap_server'          code = 'X5' symbol = 'server'            tone = ''         label = 'SAP Server' )
      ( name = 'search'              code = '13' symbol = 'search'            tone = ''         label = 'Find' )
      ( name = 'select_block'        code = '4C' symbol = 'marquee-2'         tone = ''         label = 'Select Block' )
      ( name = 'selection'           code = '7X' symbol = 'pointer'           tone = ''         label = 'Selection' )
      ( name = 'set_b'               code = '8A' symbol = 'square-letter-b'   tone = ''         label = 'Set B' )
      ( name = 'set_copy_in_a'       code = '8F' symbol = 'copy'              tone = ''         label = 'Copy to set A' )
      ( name = 'set_copy_in_b'       code = '8G' symbol = 'copy'              tone = ''         label = 'Copy to set B' )
      ( name = 'set_state'           code = '3J' symbol = 'flag'              tone = ''         label = 'Set Status' )
      ( name = 'shared_position'     code = 'L9' symbol = 'users'             tone = ''         label = 'Position with 2 owners' )
      ( name = 'short_message'       code = '47' symbol = 'message'           tone = ''         label = 'Short message' )
      ( name = 'show_events'         code = 'ET' symbol = 'bolt'              tone = ''         label = 'Display event' )
      ( name = 'show_external_jobs'  code = 'EP' symbol = 'external-link'     tone = ''         label = 'Display external jobs' )
      ( name = 'simulate'            code = '8Z' symbol = 'flask-2'           tone = ''         label = 'Simulate' )
      ( name = 'skip'                code = '43' symbol = 'player-skip-forward' tone = ''         label = 'Skip' )
      ( name = 'spool_request'       code = 'EQ' symbol = 'printer'           tone = ''         label = 'Spool request' )
      ( name = 'stack'               code = '3B' symbol = 'stack-2'           tone = ''         label = 'Stack' )
      ( name = 'statistics'          code = 'FG' symbol = 'chart-bar'         tone = ''         label = 'Call warehouse statistics' )
      ( name = 'status'              code = 'EI' symbol = 'info-square-rounded' tone = ''         label = 'System Status' )
      ( name = 'status_alert'        code = 'MD' symbol = 'gauge'             tone = 'warning'  label = 'Status critical' )
      ( name = 'status_best'         code = 'MF' symbol = 'gauge'             tone = 'success'  label = 'Status very good' )
      ( name = 'status_booked'       code = 'B4' symbol = 'circle-check'      tone = 'success'  label = 'Booking status: booked' )
      ( name = 'status_critical'     code = 'OJ' symbol = 'gauge'             tone = 'error'    label = 'Status very critical' )
      ( name = 'status_ok'           code = 'ME' symbol = 'gauge'             tone = 'success'  label = 'Status good' )
      ( name = 'status_open'         code = 'B3' symbol = 'circle-dashed'     tone = 'info'     label = 'Booking status: open' )
      ( name = 'status_overview'     code = 'F9' symbol = 'layout-dashboard'  tone = ''         label = 'Display status overview' )
      ( name = 'status_partly_booked' code = 'B5' symbol = 'circle-half-2'     tone = 'warning'  label = 'Booking status: partially booked' )
      ( name = 'status_reverse'      code = 'B6' symbol = 'circle-x'          tone = 'error'    label = 'Booking status: canceled' )
      ( name = 'stock'               code = 'EL' symbol = 'packages'          tone = ''         label = 'Number' )
      ( name = 'store'               code = 'C0' symbol = 'archive'           tone = ''         label = 'Archive' )
      ( name = 'storno'              code = 'BA' symbol = 'receipt-refund'    tone = ''         label = 'Cancellation' )
      ( name = 'structure'           code = 'HP' symbol = 'braces'            tone = ''         label = 'Data type "Structure"' )
      ( name = 'submit'              code = '8W' symbol = 'send'              tone = ''         label = 'Forward' )
      ( name = 'sym_log_server'      code = 'G9' symbol = 'server-cog'        tone = ''         label = 'Logical application server' )
      ( name = 'system_extended_help' code = '5E' symbol = 'book'              tone = ''         label = 'Application help' )
      ( name = 'system_local_copy'   code = '4O' symbol = 'copy'              tone = ''         label = 'Copy (local)' )
      ( name = 'system_local_paste'  code = '4P' symbol = 'clipboard'         tone = ''         label = 'Paste (local)' )
      ( name = 'system_play'         code = 'I6' symbol = 'player-play'       tone = ''         label = 'Run recording' )
      ( name = 'system_possible_entries' code = '4J' symbol = 'list-search'       tone = ''         label = 'Possible Entries' )
      ( name = 'system_shortcut'     code = '8T' symbol = 'external-link'     tone = ''         label = 'Shortcut to create session' )
      ( name = 'target_group'        code = 'PF' symbol = 'target'            tone = ''         label = 'Target Group' )
      ( name = 'task'                code = 'BK' symbol = 'clipboard-check'   tone = ''         label = 'Task' )
      ( name = 'tbh_hold'            code = 'L3' symbol = 'user-pause'        tone = ''         label = 'To Be Hired/Hold' )
      ( name = 'te_advance_payment'  code = '93' symbol = 'cash'              tone = ''         label = 'Advance' )
      ( name = 'terminated_org_unit' code = 'LF' symbol = 'sitemap'           tone = 'inactive' label = 'Delimited organizational units' )
      ( name = 'text_act'            code = '6X' symbol = 'file-text'         tone = ''         label = 'Texts' )
      ( name = 'text_field'          code = 'OB' symbol = 'forms'             tone = ''         label = 'Text Field' )
      ( name = 'text_ina'            code = '6Y' symbol = 'file-text'         tone = 'inactive' label = 'Texts' )
      ( name = 'toggle_display'      code = 'K6' symbol = 'switch-horizontal' tone = ''         label = 'Change view - basic <-> detail' )
      ( name = 'total_left'          code = '0B' symbol = 'arrow-bar-to-left' tone = ''         label = 'Extreme left' )
      ( name = 'transfer'            code = 'KB' symbol = 'transfer'          tone = ''         label = 'Transfer' )
      ( name = 'transfer_structure'  code = '9W' symbol = 'arrows-shuffle'    tone = ''         label = 'Transfer structure active' )
      ( name = 'transfer_structure_ina' code = 'MU' symbol = 'arrows-shuffle'    tone = 'inactive' label = 'Transfer structure, inactive' )
      ( name = 'trend_decreasing'    code = 'M9' symbol = 'trending-down'     tone = 'warning'  label = 'Trend falling slightly' )
      ( name = 'trend_down'          code = 'M8' symbol = 'trending-down'     tone = 'error'    label = 'Trend falling' )
      ( name = 'trend_rising'        code = 'MB' symbol = 'trending-up'       tone = 'success'  label = 'Trend rising slightly' )
      ( name = 'trend_unchanged'     code = 'MA' symbol = 'arrow-narrow-right' tone = ''         label = 'Trend stagnating' )
      ( name = 'trend_up'            code = 'MC' symbol = 'trending-up'       tone = 'success'  label = 'Trend rising' )
      ( name = 'unpack'              code = 'E9' symbol = 'package-export'    tone = ''         label = 'Unpack' )
      ( name = 'unspecified_four'    code = 'KZ' symbol = 'circle-dashed-number-4' tone = ''         label = 'Not specified (4)' )
      ( name = 'unspecified_one'     code = 'KW' symbol = 'circle-dashed-number-1' tone = ''         label = 'Not specified (1)' )
      ( name = 'unspecified_three'   code = 'KY' symbol = 'circle-dashed-number-3' tone = ''         label = 'Not specified (3)' )
      ( name = 'unspecified_two'     code = 'KX' symbol = 'circle-dashed-number-2' tone = ''         label = 'Not specified (2)' )
      ( name = 'usergroup'           code = 'ID' symbol = 'users-group'       tone = ''         label = 'User groups in authorization' )
      ( name = 'val_quantity_structure' code = 'Q8' symbol = 'chart-treemap'     tone = ''         label = 'Valued Quantity Structure' )
      ( name = 'variable'            code = '4M' symbol = 'variable'          tone = ''         label = 'Variable' )
      ( name = 'video'               code = '1X' symbol = 'video'             tone = ''         label = 'Video' )
      ( name = 'viewer_optical_archive' code = '0U' symbol = 'eye'               tone = ''         label = 'Optical archive viewer' )
      ( name = 'warehouse'           code = 'A1' symbol = 'building-warehouse' tone = ''         label = 'Central Warehouse' )
      ( name = 'wf_link'             code = 'CQ' symbol = 'link'              tone = ''         label = 'Define data flow' )
      ( name = 'wf_unlink'           code = 'CR' symbol = 'unlink'            tone = ''         label = 'Break down data flow' )
      ( name = 'wf_workitem_completed' code = 'CX' symbol = 'clipboard-check'   tone = 'success'  label = 'Work item finished' )
      ( name = 'wf_workitem_error'   code = 'CY' symbol = 'clipboard-x'       tone = 'error'    label = 'Work item has error' )
      ( name = 'wf_workitem_ol'      code = 'E5' symbol = 'mail'              tone = ''         label = 'SAP work item in Outlook' )
      ( name = 'wizard'              code = 'BY' symbol = 'wand'              tone = ''         label = 'Wizard' )
      ( name = 'workflow_activity'   code = '5H' symbol = 'activity'          tone = ''         label = 'Activity' )
      ( name = 'working_plan'        code = 'AJ' symbol = 'route'             tone = ''         label = 'Routing' )
      ( name = 'ws_start_whse_proc_backgr' code = 'LT' symbol = 'clock-play'        tone = ''         label = 'Start whse proc. in background' )
      ( name = 'ws_truck'            code = '7Q' symbol = 'truck'             tone = ''         label = 'Transport (truck)' )
      ( name = 'xml_doc'             code = 'R4' symbol = 'file-type-xml'     tone = ''         label = 'XML document' )
* no quick info in the SAP ICON table, so the label follows the name
      ( name = 'rating_minus'        code = 'P6' symbol = 'thumb-down'        tone = ''         label = 'Rating minus' )
      ( name = 'wd_context'          code = 'S8' symbol = 'hierarchy'         tone = ''         label = 'Web Dynpro context' )
      ( name = 'wd_iframe'           code = 'T9' symbol = 'frame'             tone = ''         label = 'Web Dynpro iframe' )
      ( name = 'wd_table'            code = 'T4' symbol = 'table'             tone = ''         label = 'Web Dynpro table' )
      ( name = 'wd_view'             code = 'RN' symbol = 'layout'            tone = ''         label = 'Web Dynpro view' )
      ( name = 'wd_view_area'        code = 'RR' symbol = 'layout-board'      tone = ''         label = 'Web Dynpro view area' )
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

  METHOD prune_sprite.
    CONSTANTS lc_reference TYPE string VALUE `#wb-icon-`.
    CONSTANTS lc_symbol TYPE string VALUE `<symbol id="wb-icon-`.
    CONSTANTS lc_symbol_end TYPE string VALUE `</symbol>`.
    CONSTANTS lc_id_chars TYPE string VALUE `abcdefghijklmnopqrstuvwxyz0123456789-`.
    DATA lt_parts TYPE string_table.
    DATA lt_used TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA lv_length TYPE i.
    DATA lv_id TYPE string.

    SPLIT iv_html AT lc_reference INTO TABLE lt_parts.
    LOOP AT lt_parts INTO DATA(lv_part) FROM 2.
      lv_length = 0.
      WHILE lv_length < strlen( lv_part ) AND lv_part+lv_length(1) CA lc_id_chars.
        lv_length = lv_length + 1.
      ENDWHILE.
      INSERT substring( val = lv_part
                        len = lv_length ) INTO TABLE lt_used.
    ENDLOOP.

    SPLIT iv_html AT lc_symbol INTO TABLE lt_parts.
    LOOP AT lt_parts INTO lv_part.
      IF sy-tabix = 1.
        rv_html = lv_part.
        CONTINUE.
      ENDIF.
* find and substring rather than substring_after, which the open-abap runtime
* matches only up to the first line break, losing the rest of the page.
      lv_id = substring( val = lv_part
                         len = nmax( val1 = 0
                                     val2 = find( val = lv_part
                                                  sub = `"` ) ) ).
      lv_length = find( val = lv_part
                        sub = lc_symbol_end ).
      IF line_exists( lt_used[ table_line = lv_id ] ) OR lv_length < 0.
        rv_html = rv_html && lc_symbol && lv_part.
      ELSE.
        rv_html = rv_html && substring( val = lv_part
                                        off = lv_length + strlen( lc_symbol_end ) ).
      ENDIF.
    ENDLOOP.
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
      '<symbol id="wb-icon-activity" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12h4l3 8l4 -16l3 8h4" /></symbol>' &&
      '<symbol id="wb-icon-address-book" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6v12a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2" /><path d="M10 16h6" /><path d="M11 11a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M4 8h3" /><path d="M4 12h3" /><path d="M4 16h3" /></symbol>' &&
      '<symbol id="wb-icon-adjustments" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M6 4v4" /><path d="M6 12v8" /><path d="M10 16a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M12 4v10" /><path d="M12 18v2" /><path d="M16 7a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M18 4v1" /><path d="M18 9v11" /></symbol>' &&
      '<symbol id="wb-icon-affiliate" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5.931 6.936l1.275 4.249m5.607 5.609l4.251 1.275" /><path d="M11.683 12.317l5.759 -5.759" /><path d="M4 5.5a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0" /><path d="M17 5.5a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0" /><path d="M17 18.5a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0" /><path d="M4 15.5a4.5 4.5 0 1 0 9 0a4.5 4.5 0 1 0 -9 0" /></symbol>' &&
      '<symbol id="wb-icon-alarm" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 13a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M12 10l0 3l2 0" /><path d="M7 4l-2.75 2" /><path d="M17 4l2.75 2" /></symbol>' &&
      '<symbol id="wb-icon-api" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 13h5" /><path d="M12 16v-8h3a2 2 0 0 1 2 2v1a2 2 0 0 1 -2 2h-3" /><path d="M20 8v8" /><path d="M9 16v-5.5a2.5 2.5 0 0 0 -5 0v5.5" /></symbol>' &&
      '<symbol id="wb-icon-archive" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2" /><path d="M5 8v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-10" /><path d="M10 12l4 0" /></symbol>' &&
      '<symbol id="wb-icon-arrow-autofit-width" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12v-6a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v6" /><path d="M10 18h-7" /><path d="M21 18h-7" /><path d="M6 15l-3 3l3 3" /><path d="M18 15l3 3l-3 3" /></symbol>' &&
      '<symbol id="wb-icon-arrow-back" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l-4 4l4 4m-4 -4h11a4 4 0 0 0 0 -8h-1" /></symbol>' &&
      '<symbol id="wb-icon-arrow-bar-to-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 12l10 0" /><path d="M10 12l4 4" /><path d="M10 12l4 -4" /><path d="M4 4l0 16" /></symbol>' &&
      '<symbol id="wb-icon-arrow-narrow-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l14 0" /><path d="M15 16l4 -4" /><path d="M15 8l4 4" /></symbol>' &&
      '<symbol id="wb-icon-arrow-right-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 15l3 -3l-3 -3" /><path d="M3 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M7 12h14" /></symbol>' &&
      '<symbol id="wb-icon-arrows-diff" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 16h10" /><path d="M11 16l4 4" /><path d="M11 16l4 -4" /><path d="M13 8h-10" /><path d="M13 8l-4 4" /><path d="M13 8l-4 -4" /></symbol>' &&
      '<symbol id="wb-icon-arrows-horizontal" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 8l-4 4l4 4" /><path d="M17 8l4 4l-4 4" /><path d="M3 12l18 0" /></symbol>' &&
      '<symbol id="wb-icon-arrows-join" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h5l3.5 5h9.5" /><path d="M3 17h5l3.495 -5" /><path d="M18 15l3 -3l-3 -3" /></symbol>' &&
      '<symbol id="wb-icon-arrows-move" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 9l3 3l-3 3" /><path d="M15 12h6" /><path d="M6 9l-3 3l3 3" /><path d="M3 12h6" /><path d="M9 18l3 3l3 -3" /><path d="M12 15v6" /><path d="M15 6l-3 -3l-3 3" /><path d="M12 3v6" /></symbol>' &&
      '<symbol id="wb-icon-arrows-shuffle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 4l3 3l-3 3" /><path d="M18 20l3 -3l-3 -3" /><path d="M3 7h3a5 5 0 0 1 5 5a5 5 0 0 0 5 5h5" /><path d="M21 7h-5a4.978 4.978 0 0 0 -3 1m-4 8a4.984 4.984 0 0 1 -3 1h-3" /></symbol>' &&
      '<symbol id="wb-icon-asterisk" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 12l8 -4.5" /><path d="M12 12v9" /><path d="M12 12l-8 -4.5" /><path d="M12 12l8 4.5" /><path d="M12 3v9" /><path d="M12 12l-8 4.5" /></symbol>' &&
      '<symbol id="wb-icon-bell-ringing" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 5a2 2 0 0 1 4 0a7 7 0 0 1 4 6v3a4 4 0 0 0 2 3h-16a4 4 0 0 0 2 -3v-3a7 7 0 0 1 4 -6" /><path d="M9 17v1a3 3 0 0 0 6 0v-1" /><path d="M21 6.727a11.05 11.05 0 0 0 -2.794 -3.727" /><path d="M3 6.727a11.05 11.05 0 0 1 2.792 -3.727" /></symbol>' &&
      '<symbol id="wb-icon-bolt-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3l18 18" /><path d="M15.212 15.21l-4.212 5.79v-7h-6l3.79 -5.21m1.685 -2.32l2.525 -3.47v6m1 1h5l-2.104 2.893" /></symbol>' &&
      '<symbol id="wb-icon-book" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 19a9 9 0 0 1 9 0a9 9 0 0 1 9 0" /><path d="M3 6a9 9 0 0 1 9 0a9 9 0 0 1 9 0" /><path d="M3 6l0 13" /><path d="M12 6l0 13" /><path d="M21 6l0 13" /></symbol>' &&
      '<symbol id="wb-icon-braces" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4a2 2 0 0 0 -2 2v3a2 3 0 0 1 -2 3a2 3 0 0 1 2 3v3a2 2 0 0 0 2 2" /><path d="M17 4a2 2 0 0 1 2 2v3a2 3 0 0 0 2 3a2 3 0 0 0 -2 3v3a2 2 0 0 1 -2 2" /></symbol>' &&
      '<symbol id="wb-icon-building-bank" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21l18 0" /><path d="M3 10l18 0" /><path d="M5 6l7 -3l7 3" /><path d="M4 10l0 11" /><path d="M20 10l0 11" /><path d="M8 14l0 3" /><path d="M12 14l0 3" /><path d="M16 14l0 3" /></symbol>' &&
      '<symbol id="wb-icon-building-factory" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 21c1.147 -4.02 1.983 -8.027 2 -12h6c.017 3.973 .853 7.98 2 12" /><path d="M12.5 13h4.5c.025 2.612 .894 5.296 2 8" /><path d="M9 5a2.4 2.4 0 0 1 2 -1a2.4 2.4 0 0 1 2 1a2.4 2.4 0 0 0 2 1a2.4 2.4 0 0 0 2 -1a2.4 2.4 0 0 1 2 -1a2.4 2.4 0 0 1 2 1" /><path d="M3 21l19 0" /></symbol>' &&
      '<symbol id="wb-icon-building-store" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21l18 0" /><path d="M3 7v1a3 3 0 0 0 6 0v-1m0 1a3 3 0 0 0 6 0v-1m0 1a3 3 0 0 0 6 0v-1h-18l2 -4h14l2 4" /><path d="M5 21l0 -10.15" /><path d="M19 21l0 -10.15" /><path d="M9 21v-4a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v4" /></symbol>' &&
      '<symbol id="wb-icon-bulb" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12h1m8 -9v1m8 8h1m-15.4 -6.4l.7 .7m12.1 -.7l-.7 .7" /><path d="M9 16a5 5 0 1 1 6 0a3.5 3.5 0 0 0 -1 3a2 2 0 0 1 -4 0a3.5 3.5 0 0 0 -1 -3" /><path d="M9.7 17l4.6 0" /></symbol>' &&
      '<symbol id="wb-icon-calendar-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11.5 21h-5.5a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v6" /><path d="M16 3v4" /><path d="M8 3v4" /><path d="M4 11h16" /><path d="M15 19l2 2l4 -4" /></symbol>' &&
      '<symbol id="wb-icon-calendar-repeat" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12.5 21h-6.5a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v3" /><path d="M16 3v4" /><path d="M8 3v4" /><path d="M4 11h12" /><path d="M20 14l2 2h-3" /><path d="M20 18l2 -2" /><path d="M19 16a3 3 0 1 0 2 5.236" /></symbol>' &&
      '<symbol id="wb-icon-calendar-time" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11.795 21h-6.795a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v4" /><path d="M14 18a4 4 0 1 0 8 0a4 4 0 1 0 -8 0" /><path d="M15 3v4" /><path d="M7 3v4" /><path d="M3 11h16" /><path d="M18 16.496v1.504l1 1" /></symbol>' &&
      '<symbol id="wb-icon-cash" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 15h-3a1 1 0 0 1 -1 -1v-8a1 1 0 0 1 1 -1h12a1 1 0 0 1 1 1v3" /><path d="M7 10a1 1 0 0 1 1 -1h12a1 1 0 0 1 1 1v8a1 1 0 0 1 -1 1h-12a1 1 0 0 1 -1 -1l0 -8" /><path d="M12 14a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /></symbol>' &&
      '<symbol id="wb-icon-category" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h6v6h-6l0 -6" /><path d="M14 4h6v6h-6l0 -6" /><path d="M4 14h6v6h-6l0 -6" /><path d="M14 17a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /></symbol>' &&
      '<symbol id="wb-icon-certificate" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M13 17.5v4.5l2 -1.5l2 1.5v-4.5" /><path d="M10 19h-5a2 2 0 0 1 -2 -2v-10c0 -1.1 .9 -2 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -1 1.73" /><path d="M6 9l12 0" /><path d="M6 12l3 0" /><path d="M6 15l2 0" /></symbol>' &&
      '<symbol id="wb-icon-chart-line" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19l16 0" /><path d="M4 15l4 -6l4 2l4 -5l4 4" /></symbol>' &&
      '<symbol id="wb-icon-chart-pie" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 3.2a9 9 0 1 0 10.8 10.8a1 1 0 0 0 -1 -1h-6.8a2 2 0 0 1 -2 -2v-7a.9 .9 0 0 0 -1 -.8" /><path d="M15 3.5a9 9 0 0 1 5.5 5.5h-4.5a1 1 0 0 1 -1 -1v-4.5" /></symbol>' &&
      '<symbol id="wb-icon-chart-treemap" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2l0 -12" /><path d="M12 4v16" /><path d="M4 15h8" /><path d="M12 12h8" /><path d="M16 12v8" /><path d="M16 16h4" /></symbol>' &&
      '<symbol id="wb-icon-checkbox" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3l8 -8" /><path d="M20 12v6a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h9" /></symbol>' &&
      '<symbol id="wb-icon-circle-dashed" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.56 3.69a9 9 0 0 0 -2.92 1.95" /><path d="M3.69 8.56a9 9 0 0 0 -.69 3.44" /><path d="M3.69 15.44a9 9 0 0 0 1.95 2.92" /><path d="M8.56 20.31a9 9 0 0 0 3.44 .69" /><path d="M15.44 20.31a9 9 0 0 0 2.92 -1.95" /><path d="M20.31 15.44a9 9 0 0 0 .69 -3.44" /><path d="M20.31 8.56a9 9 0 0 0 -1.95 -2.92" /><path d="M15.44 3.69a9 9 0 0 0 -3.44 -.69" /></symbol>' &&
      '<symbol id="wb-icon-circle-dashed-number-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.56 3.69a9 9 0 0 0 -2.92 1.95" /><path d="M3.69 8.56a9 9 0 0 0 -.69 3.44" /><path d="M3.69 15.44a9 9 0 0 0 1.95 2.92" /><path d="M8.56 20.31a9 9 0 0 0 3.44 .69" /><path d="M15.44 20.31a9 9 0 0 0 2.92 -1.95" /><path d="M20.31 15.44a9 9 0 0 0 .69 -3.44" /><path d="M20.31 8.56a9 9 0 0 0 -1.95 -2.92" /><path d="M15.44 3.69a9 9 0 0 0 -3.44 -.69" /><path d="M10 10l2 -2v8" /></symbol>' &&
      '<symbol id="wb-icon-circle-dashed-number-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.56 3.69a9 9 0 0 0 -2.92 1.95" /><path d="M3.69 8.56a9 9 0 0 0 -.69 3.44" /><path d="M3.69 15.44a9 9 0 0 0 1.95 2.92" /><path d="M8.56 20.31a9 9 0 0 0 3.44 .69" /><path d="M15.44 20.31a9 9 0 0 0 2.92 -1.95" /><path d="M20.31 15.44a9 9 0 0 0 .69 -3.44" /><path d="M20.31 8.56a9 9 0 0 0 -1.95 -2.92" /><path d="M15.44 3.69a9 9 0 0 0 -3.44 -.69" /><path d="M10 8h3a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-2a1 1 0 0 0 -1 1v2a1 1 0 0 0 1 1h3" /></symbol>' &&
      '<symbol id="wb-icon-circle-dashed-number-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.56 3.69a9 9 0 0 0 -2.92 1.95" /><path d="M3.69 8.56a9 9 0 0 0 -.69 3.44" /><path d="M3.69 15.44a9 9 0 0 0 1.95 2.92" /><path d="M8.56 20.31a9 9 0 0 0 3.44 .69" /><path d="M15.44 20.31a9 9 0 0 0 2.92 -1.95" /><path d="M20.31 15.44a9 9 0 0 0 .69 -3.44" /><path d="M20.31 8.56a9 9 0 0 0 -1.95 -2.92" /><path d="M15.44 3.69a9 9 0 0 0 -3.44 -.69" /><path d="M10 8h2.5a1.5 1.5 0 0 1 1.5 1.5v1a1.5 1.5 0 0 1 -1.5 1.5h-1.5h1.5a1.5 1.5 0 0 1 1.5 1.5v1a1.5 1.5 0 0 1 -1.5 1.5h-2.5" /></symbol>' &&
      '<symbol id="wb-icon-circle-dashed-number-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.56 3.69a9 9 0 0 0 -2.92 1.95" /><path d="M3.69 8.56a9 9 0 0 0 -.69 3.44" /><path d="M3.69 15.44a9 9 0 0 0 1.95 2.92" /><path d="M8.56 20.31a9 9 0 0 0 3.44 .69" /><path d="M15.44 20.31a9 9 0 0 0 2.92 -1.95" /><path d="M20.31 15.44a9 9 0 0 0 .69 -3.44" /><path d="M20.31 8.56a9 9 0 0 0 -1.95 -2.92" /><path d="M15.44 3.69a9 9 0 0 0 -3.44 -.69" /><path d="M10 8v3a1 1 0 0 0 1 1h3" /><path d="M14 8v8" /></symbol>' &&
      '<symbol id="wb-icon-circle-dot" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /></symbol>' &&
      '<symbol id="wb-icon-circle-half-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M12 3v18" /><path d="M12 14l7 -7" /><path d="M12 19l8.5 -8.5" /><path d="M12 9l4.5 -4.5" /></symbol>' &&
      '<symbol id="wb-icon-clipboard-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /><path d="M9 14l2 2l4 -4" /></symbol>' &&
      '<symbol id="wb-icon-clipboard-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /><path d="M10 14h4" /><path d="M12 12v4" /></symbol>' &&
      '<symbol id="wb-icon-clipboard-x" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /><path d="M10 12l4 4m0 -4l-4 4" /></symbol>' &&
      '<symbol id="wb-icon-code" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 8l-4 4l4 4" /><path d="M17 8l4 4l-4 4" /><path d="M14 4l-4 16" /></symbol>' &&
      '<symbol id="wb-icon-coin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M14.8 9a2 2 0 0 0 -1.8 -1h-2a2 2 0 1 0 0 4h2a2 2 0 1 1 0 4h-2a2 2 0 0 1 -1.8 -1" /><path d="M12 7v10" /></symbol>' &&
      '<symbol id="wb-icon-column-insert-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-14a1 1 0 0 1 1 -1" /><path d="M15 12l4 0" /><path d="M17 10l0 4" /></symbol>' &&
      '<symbol id="wb-icon-cube" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16.008v-8.018a1.98 1.98 0 0 0 -1 -1.717l-7 -4.008a2.016 2.016 0 0 0 -2 0l-7 4.008c-.619 .355 -1 1.01 -1 1.718v8.018c0 .709 .381 1.363 1 1.717l7 4.008a2.016 2.016 0 0 0 2 0l7 -4.008c.619 -.355 1 -1.01 1 -1.718" /><path d="M12 22v-10" /><path d="M12 12l8.73 -5.04" /><path d="M3.27 6.96l8.73 5.04" /></symbol>' &&
      '<symbol id="wb-icon-device-desktop-analytics" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a1 1 0 0 1 1 -1h16a1 1 0 0 1 1 1v10a1 1 0 0 1 -1 1h-16a1 1 0 0 1 -1 -1l0 -10" /><path d="M7 20h10" /><path d="M9 16v4" /><path d="M15 16v4" /><path d="M9 12v-4" /><path d="M12 12v-1" /><path d="M15 12v-2" /><path d="M12 12v-1" /></symbol>' &&
      '<symbol id="wb-icon-dimensions" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5h11" /><path d="M12 7l2 -2l-2 -2" /><path d="M5 3l-2 2l2 2" /><path d="M19 10v11" /><path d="M17 19l2 2l2 -2" /><path d="M21 12l-2 -2l-2 2" /><path d="M3 12a2 2 0 0 1 2 -2h7a2 2 0 0 1 2 2v7a2 2 0 0 1 -2 2h-7a2 2 0 0 1 -2 -2l0 -7" /></symbol>' &&
      '<symbol id="wb-icon-equal" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 10h14" /><path d="M5 14h14" /></symbol>' &&
      '<symbol id="wb-icon-equal-not" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 10h14" /><path d="M5 14h14" /><path d="M5 19l14 -14" /></symbol>' &&
      '<symbol id="wb-icon-external-link" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 6h-6a2 2 0 0 0 -2 2v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-6" /><path d="M11 13l9 -9" /><path d="M15 4h5v5" /></symbol>' &&
      '<symbol id="wb-icon-file-arrow-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M9 15h6" /><path d="M12.5 17.5l2.5 -2.5l-2.5 -2.5" /></symbol>' &&
      '<symbol id="wb-icon-file-database" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 12.75a4 1.75 0 1 0 8 0a4 1.75 0 1 0 -8 0" /><path d="M8 12.5v3.75c0 .966 1.79 1.75 4 1.75s4 -.784 4 -1.75v-3.75" /><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /></symbol>' &&
      '<symbol id="wb-icon-file-description" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M9 17h6" /><path d="M9 13h6" /></symbol>' &&
      '<symbol id="wb-icon-file-invoice" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M9 7l1 0" /><path d="M9 13l6 0" /><path d="M13 17l2 0" /></symbol>' &&
      '<symbol id="wb-icon-file-minus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M9 14l6 0" /></symbol>' &&
      '<symbol id="wb-icon-file-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M12 11l0 6" /><path d="M9 14l6 0" /></symbol>' &&
      '<symbol id="wb-icon-file-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M12 21h-5a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v4.5" /><path d="M14 17.5a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0 -5 0" /><path d="M18.5 19.5l2.5 2.5" /></symbol>' &&
      '<symbol id="wb-icon-file-type-html" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4" /><path d="M2 21v-6" /><path d="M5 15v6" /><path d="M2 18h3" /><path d="M20 15v6h2" /><path d="M13 21v-6l2 3l2 -3v6" /><path d="M7.5 15h3" /><path d="M9 15v6" /></symbol>' &&
      '<symbol id="wb-icon-file-type-xml" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4" /><path d="M4 15l4 6" /><path d="M4 21l4 -6" /><path d="M19 15v6h3" /><path d="M11 21v-6l2.5 3l2.5 -3v6" /></symbol>' &&
      '<symbol id="wb-icon-flag" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 5a5 5 0 0 1 7 0a5 5 0 0 0 7 0v9a5 5 0 0 1 -7 0a5 5 0 0 0 -7 0v-9" /><path d="M5 21v-7" /></symbol>' &&
      '<symbol id="wb-icon-flask-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6.1 15h11.8" /><path d="M14 3v7.342a6 6 0 0 1 1.318 10.658h-6.635a6 6 0 0 1 1.317 -10.66v-7.34h4" /><path d="M9 3h6" /></symbol>' &&
      '<symbol id="wb-icon-forms" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a3 3 0 0 0 -3 3v12a3 3 0 0 0 3 3" /><path d="M6 3a3 3 0 0 1 3 3v12a3 3 0 0 1 -3 3" /><path d="M13 7h7a1 1 0 0 1 1 1v8a1 1 0 0 1 -1 1h-7" /><path d="M5 7h-1a1 1 0 0 0 -1 1v8a1 1 0 0 0 1 1h1" /><path d="M17 12h.01" /><path d="M13 12h.01" /></symbol>' &&
      '<symbol id="wb-icon-frame" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7l16 0" /><path d="M4 17l16 0" /><path d="M7 4l0 16" /><path d="M17 4l0 16" /></symbol>' &&
      '<symbol id="wb-icon-gauge" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M13.41 10.59l2.59 -2.59" /><path d="M7 12a5 5 0 0 1 5 -5" /></symbol>' &&
      '<symbol id="wb-icon-gavel" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 10l7.383 7.418c.823 .82 .823 2.148 0 2.967a2.11 2.11 0 0 1 -2.976 0l-7.407 -7.385" /><path d="M6 9l4 4" /><path d="M13 10l-4 -4" /><path d="M3 21h7" /><path d="M6.793 15.793l-3.586 -3.586a1 1 0 0 1 0 -1.414l2.293 -2.293l.5 .5l3 -3l-.5 -.5l2.293 -2.293a1 1 0 0 1 1.414 0l3.586 3.586a1 1 0 0 1 0 1.414l-2.293 2.293l-.5 -.5l-3 3l.5 .5l-2.293 2.293a1 1 0 0 1 -1.414 0" /></symbol>' &&
      '<symbol id="wb-icon-gift" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9a1 1 0 0 1 1 -1h16a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-16a1 1 0 0 1 -1 -1l0 -2" /><path d="M12 8l0 13" /><path d="M19 12v7a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-7" /><path d="M7.5 8a2.5 2.5 0 0 1 0 -5a4.8 8 0 0 1 4.5 5a4.8 8 0 0 1 4.5 -5a2.5 2.5 0 0 1 0 5" /></symbol>' &&
      '<symbol id="wb-icon-hand-stop" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 13v-7.5a1.5 1.5 0 0 1 3 0v6.5" /><path d="M11 5.5v-2a1.5 1.5 0 1 1 3 0v8.5" /><path d="M14 5.5a1.5 1.5 0 0 1 3 0v6.5" /><path d="M17 7.5a1.5 1.5 0 0 1 3 0v8.5a6 6 0 0 1 -6 6h-2h.208a6 6 0 0 1 -5.012 -2.7a69.74 69.74 0 0 1 -.196 -.3c-.312 -.479 -1.407 -2.388 -3.286 -5.728a1.5 1.5 0 0 1 .536 -2.022a1.867 1.867 0 0 1 2.28 .28l1.47 1.47" /></symbol>' &&
      '<symbol id="wb-icon-heart-handshake" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19.5 12.572l-7.5 7.428l-7.5 -7.428a5 5 0 1 1 7.5 -6.566a5 5 0 1 1 7.5 6.572" /><path d="M12 6l-3.293 3.293a1 1 0 0 0 0 1.414l.543 .543c.69 .69 1.81 .69 2.5 0l1 -1a3.182 3.182 0 0 1 4.5 0l2.25 2.25" /><path d="M12.5 15.5l2 2" /><path d="M15 13l2 2" /></symbol>' &&
      '<symbol id="wb-icon-heart-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3l18 18" /><path d="M19.5 12.572l-1.5 1.428m-2 2l-4 4l-7.5 -7.428a5 5 0 0 1 -1.288 -5.068a4.976 4.976 0 0 1 1.788 -2.504m3 -1c1.56 0 3.05 .727 4 2a5 5 0 1 1 7.5 6.572" /></symbol>' &&
      '<symbol id="wb-icon-hierarchy" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 5a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M3 19a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M17 19a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M6.5 17.5l5.5 -4.5l5.5 4.5" /><path d="M12 7l0 6" /></symbol>' &&
      '<symbol id="wb-icon-hierarchy-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 3h4v4h-4l0 -4" /><path d="M3 17h4v4h-4l0 -4" /><path d="M17 17h4v4h-4l0 -4" /><path d="M7 17l5 -4l5 4" /><path d="M12 7l0 6" /></symbol>' &&
      '<symbol id="wb-icon-hierarchy-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 5a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M6 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M10 19a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M18 19a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M2 19a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M14 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M5 17l2 -3" /><path d="M9 10l2 -3" /><path d="M13 7l2 3" /><path d="M17 14l2 3" /><path d="M15 14l-2 3" /><path d="M9 14l2 3" /></symbol>' &&
      '<symbol id="wb-icon-highlight" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 19h4l10.5 -10.5a2.828 2.828 0 1 0 -4 -4l-10.5 10.5v4" /><path d="M12.5 5.5l4 4" /><path d="M4.5 13.5l4 4" /><path d="M21 15v4h-8l4 -4l4 0" /></symbol>' &&
      '<symbol id="wb-icon-highlight-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 9l-6 6v4h4l6 -6m2 -2l2.503 -2.503a2.828 2.828 0 1 0 -4 -4l-2.497 2.497" /><path d="M12.5 5.5l4 4" /><path d="M4.5 13.5l4 4" /><path d="M19 15h2v2m-2 2h-6l3 -3" /><path d="M3 3l18 18" /></symbol>' &&
      '<symbol id="wb-icon-icons" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6.5a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0 -7 0" /><path d="M2.5 21h8l-4 -7l-4 7" /><path d="M14 3l7 7" /><path d="M14 10l7 -7" /><path d="M14 14h7v7h-7l0 -7" /></symbol>' &&
      '<symbol id="wb-icon-id" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v10a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3l0 -10" /><path d="M7 10a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M15 8l2 0" /><path d="M15 12l2 0" /><path d="M7 16l10 0" /></symbol>' &&
      '<symbol id="wb-icon-info-square-rounded" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 9h.01" /><path d="M11 12h1v4h1" /><path d="M12 3c7.2 0 9 1.8 9 9c0 7.2 -1.8 9 -9 9c-7.2 0 -9 -1.8 -9 -9c0 -7.2 1.8 -9 9 -9" /></symbol>' &&
      '<symbol id="wb-icon-key" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16.555 3.843l3.602 3.602a2.877 2.877 0 0 1 0 4.069l-2.643 2.643a2.877 2.877 0 0 1 -4.069 0l-.301 -.301l-6.558 6.558a2 2 0 0 1 -1.239 .578l-.175 .008h-1.172a1 1 0 0 1 -.993 -.883l-.007 -.117v-1.172a2 2 0 0 1 .467 -1.284l.119 -.13l.414 -.414h2v-2h2v-2l2.144 -2.144l-.301 -.301a2.877 2.877 0 0 1 0 -4.069l2.643 -2.643a2.877 2.877 0 0 1 4.069 0" /><path d="M15 9h.01" /></symbol>' &&
      '<symbol id="wb-icon-keyboard" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 8a2 2 0 0 1 2 -2h16a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-16a2 2 0 0 1 -2 -2l0 -8" /><path d="M6 10l0 .01" /><path d="M10 10l0 .01" /><path d="M14 10l0 .01" /><path d="M18 10l0 .01" /><path d="M6 14l0 .01" /><path d="M18 14l0 .01" /><path d="M10 14l4 .01" /></symbol>' &&
      '<symbol id="wb-icon-layout" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v1a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2l0 -1" /><path d="M4 15a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v3a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2l0 -3" /><path d="M14 6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2l0 -12" /></symbol>' &&
      '<symbol id="wb-icon-layout-board" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2l0 -12" /><path d="M4 9h8" /><path d="M12 15h8" /><path d="M12 4v16" /></symbol>' &&
      '<symbol id="wb-icon-layout-dashboard" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 4h4a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-6a1 1 0 0 1 1 -1" /><path d="M5 16h4a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-2a1 1 0 0 1 1 -1" /><path d="M15 12h4a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-6a1 1 0 0 1 1 -1" /><path d="M15 4h4a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-2a1 1 0 0 1 1 -1" /></symbol>' &&
      '<symbol id="wb-icon-layout-navbar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2l0 -12" /><path d="M4 9l16 0" /></symbol>' &&
      '<symbol id="wb-icon-layout-navbar-collapse" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 18v-12a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2" /><path d="M4 9h16" /><path d="M10 16l2 -2l2 2" /></symbol>' &&
      '<symbol id="wb-icon-layout-navbar-expand" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 18v-12a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2" /><path d="M4 9h16" /><path d="M10 14l2 2l2 -2" /></symbol>' &&
      '<symbol id="wb-icon-lifebuoy" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0" /><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M15 15l3.35 3.35" /><path d="M9 15l-3.35 3.35" /><path d="M5.65 5.65l3.35 3.35" /><path d="M18.35 5.65l-3.35 3.35" /></symbol>' &&
      '<symbol id="wb-icon-link" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 15l6 -6" /><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464" /><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463" /></symbol>' &&
      '<symbol id="wb-icon-marquee-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6v-1a1 1 0 0 1 1 -1h1m5 0h2m5 0h1a1 1 0 0 1 1 1v1m0 5v2m0 5v1a1 1 0 0 1 -1 1h-1m-5 0h-2m-5 0h-1a1 1 0 0 1 -1 -1v-1m0 -5v-2" /></symbol>' &&
      '<symbol id="wb-icon-math-equal-greater" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 18l14 -4" /><path d="M5 14l14 -4l-14 -4" /></symbol>' &&
      '<symbol id="wb-icon-math-equal-lower" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 18l-14 -4" /><path d="M19 14l-14 -4l14 -4" /></symbol>' &&
      '<symbol id="wb-icon-math-greater" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 18l14 -6l-14 -6" /></symbol>' &&
      '<symbol id="wb-icon-math-lower" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 18l-14 -6l14 -6" /></symbol>' &&
      '<symbol id="wb-icon-message" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 9h8" /><path d="M8 13h6" /><path d="M18 4a3 3 0 0 1 3 3v8a3 3 0 0 1 -3 3h-5l-5 3v-3h-2a3 3 0 0 1 -3 -3v-8a3 3 0 0 1 3 -3h12" /></symbol>' &&
      '<symbol id="wb-icon-message-question" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 9h8" /><path d="M8 13h6" /><path d="M14 18h-1l-5 3v-3h-2a3 3 0 0 1 -3 -3v-8a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v4.5" /><path d="M19 22v.01" /><path d="M19 19a2.003 2.003 0 0 0 .914 -3.782a1.98 1.98 0 0 0 -2.414 .483" /></symbol>' &&
      '<symbol id="wb-icon-microscope" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21h14" /><path d="M6 18h2" /><path d="M7 18v3" /><path d="M9 11l3 3l6 -6l-3 -3l-6 6" /><path d="M10.5 12.5l-1.5 1.5" /><path d="M17 3l3 3" /><path d="M12 21a6 6 0 0 0 3.715 -10.712" /></symbol>' &&
      '<symbol id="wb-icon-note" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 20l7 -7" /><path d="M13 20v-6a1 1 0 0 1 1 -1h6v-7a2 2 0 0 0 -2 -2h-12a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h7" /></symbol>' &&
      '<symbol id="wb-icon-package" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l8 4.5l0 9l-8 4.5l-8 -4.5l0 -9l8 -4.5" /><path d="M12 12l8 -4.5" /><path d="M12 12l0 9" /><path d="M12 12l-8 -4.5" /><path d="M16 5.25l-8 4.5" /></symbol>' &&
      '<symbol id="wb-icon-package-export" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21l-8 -4.5v-9l8 -4.5l8 4.5v4.5" /><path d="M12 12l8 -4.5" /><path d="M12 12v9" /><path d="M12 12l-8 -4.5" /><path d="M15 18h7" /><path d="M19 15l3 3l-3 3" /></symbol>' &&
      '<symbol id="wb-icon-package-import" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21l-8 -4.5v-9l8 -4.5l8 4.5v4.5" /><path d="M12 12l8 -4.5" /><path d="M12 12v9" /><path d="M12 12l-8 -4.5" /><path d="M22 18h-7" /><path d="M18 15l-3 3l3 3" /></symbol>' &&
      '<symbol id="wb-icon-packages" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 16.5l-5 -3l5 -3l5 3v5.5l-5 3l0 -5.5" /><path d="M2 13.5v5.5l5 3" /><path d="M7 16.545l5 -3.03" /><path d="M17 16.5l-5 -3l5 -3l5 3v5.5l-5 3l0 -5.5" /><path d="M12 19l5 3" /><path d="M17 16.5l5 -3" /><path d="M12 13.5v-5.5l-5 -3l5 -3l5 3v5.5" /><path d="M7 5.03v5.455" /><path d="M12 8l5 -3" /></symbol>' &&
      '<symbol id="wb-icon-palette" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21a9 9 0 0 1 0 -18c4.97 0 9 3.582 9 8c0 1.06 -.474 2.078 -1.318 2.828c-.844 .75 -1.989 1.172 -3.182 1.172h-2.5a2 2 0 0 0 -1 3.75a1.3 1.3 0 0 1 -1 2.25" /><path d="M7.5 10.5a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M11.5 7.5a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M15.5 10.5a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /></symbol>' &&
      '<symbol id="wb-icon-pencil-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h4l10.5 -10.5a2.828 2.828 0 1 0 -4 -4l-10.5 10.5v4" /><path d="M13.5 6.5l4 4" /><path d="M15 19l2 2l4 -4" /></symbol>' &&
      '<symbol id="wb-icon-pencil-cog" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h4l10.5 -10.5a2.828 2.828 0 1 0 -4 -4l-10.5 10.5v4" /><path d="M13.5 6.5l4 4" /><path d="M17.001 19a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M19.001 15.5v1.5" /><path d="M19.001 21v1.5" /><path d="M22.032 17.25l-1.299 .75" /><path d="M17.27 20l-1.3 .75" /><path d="M15.97 17.25l1.3 .75" /><path d="M20.733 20l1.3 .75" /></symbol>' &&
      '<symbol id="wb-icon-pencil-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h4l10.5 -10.5a2.828 2.828 0 1 0 -4 -4l-10.5 10.5v4" /><path d="M13.5 6.5l4 4" /><path d="M16 19h6" /><path d="M19 16v6" /></symbol>' &&
      '<symbol id="wb-icon-player-skip-forward" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5v14l12 -7l-12 -7" /><path d="M20 5l0 14" /></symbol>' &&
      '<symbol id="wb-icon-plug" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9.785 6l8.215 8.215l-2.054 2.054a5.81 5.81 0 1 1 -8.215 -8.215l2.054 -2.054" /><path d="M4 20l3.5 -3.5" /><path d="M15 4l-3.5 3.5" /><path d="M20 9l-3.5 3.5" /></symbol>' &&
      '<symbol id="wb-icon-plug-connected" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 12l5 5l-1.5 1.5a3.536 3.536 0 1 1 -5 -5l1.5 -1.5" /><path d="M17 12l-5 -5l1.5 -1.5a3.536 3.536 0 1 1 5 5l-1.5 1.5" /><path d="M3 21l2.5 -2.5" /><path d="M18.5 5.5l2.5 -2.5" /><path d="M10 11l-2 2" /><path d="M13 14l-2 2" /></symbol>' &&
      '<symbol id="wb-icon-plug-connected-x" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 16l-4 4" /><path d="M7 12l5 5l-1.5 1.5a3.536 3.536 0 1 1 -5 -5l1.5 -1.5" /><path d="M17 12l-5 -5l1.5 -1.5a3.536 3.536 0 1 1 5 5l-1.5 1.5" /><path d="M3 21l2.5 -2.5" /><path d="M18.5 5.5l2.5 -2.5" /><path d="M10 11l-2 2" /><path d="M13 14l-2 2" /><path d="M16 16l4 4" /></symbol>' &&
      '<symbol id="wb-icon-pointer" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7.904 17.563a1.2 1.2 0 0 0 2.228 .308l2.09 -3.093l4.907 4.907a1.067 1.067 0 0 0 1.509 0l1.047 -1.047a1.067 1.067 0 0 0 0 -1.509l-4.907 -4.907l3.113 -2.09a1.2 1.2 0 0 0 -.309 -2.228l-13.582 -3.904l3.904 13.563" /></symbol>' &&
      '<symbol id="wb-icon-puzzle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h3a1 1 0 0 0 1 -1v-1a2 2 0 0 1 4 0v1a1 1 0 0 0 1 1h3a1 1 0 0 1 1 1v3a1 1 0 0 0 1 1h1a2 2 0 0 1 0 4h-1a1 1 0 0 0 -1 1v3a1 1 0 0 1 -1 1h-3a1 1 0 0 1 -1 -1v-1a2 2 0 0 0 -4 0v1a1 1 0 0 1 -1 1h-3a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1h1a2 2 0 0 0 0 -4h-1a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1" /></symbol>' &&
      '<symbol id="wb-icon-receipt" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21v-16a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v16l-3 -2l-2 2l-2 -2l-2 2l-2 -2l-3 2m4 -14h6m-6 4h6m-2 4h2" /></symbol>' &&
      '<symbol id="wb-icon-receipt-refund" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21v-16a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v16l-3 -2l-2 2l-2 -2l-2 2l-2 -2l-3 2" /><path d="M15 14v-2a2 2 0 0 0 -2 -2h-4l2 -2m0 4l-2 -2" /></symbol>' &&
      '<symbol id="wb-icon-replace" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 4a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4" /><path d="M15 16a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4" /><path d="M21 11v-3a2 2 0 0 0 -2 -2h-6l3 3m0 -6l-3 3" /><path d="M3 13v3a2 2 0 0 0 2 2h6l-3 -3m0 6l3 -3" /></symbol>' &&
      '<symbol id="wb-icon-report" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h5.697" /><path d="M18 14v4h4" /><path d="M18 11v-4a2 2 0 0 0 -2 -2h-2" /><path d="M8 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /><path d="M14 18a4 4 0 1 0 8 0a4 4 0 1 0 -8 0" /><path d="M8 11h4" /><path d="M8 15h3" /></symbol>' &&
      '<symbol id="wb-icon-report-analytics" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /><path d="M9 17v-5" /><path d="M12 17v-1" /><path d="M15 17v-3" /></symbol>' &&
      '<symbol id="wb-icon-route" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 19a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M19 7a2 2 0 1 0 0 -4a2 2 0 0 0 0 4" /><path d="M11 19h5.5a3.5 3.5 0 0 0 0 -7h-8a3.5 3.5 0 0 1 0 -7h4.5" /></symbol>' &&
      '<symbol id="wb-icon-ruler-measure" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19.875 12c.621 0 1.125 .512 1.125 1.143v5.714c0 .631 -.504 1.143 -1.125 1.143h-15.875a1 1 0 0 1 -1 -1v-5.857c0 -.631 .504 -1.143 1.125 -1.143h15.75" /><path d="M9 12v2" /><path d="M6 12v3" /><path d="M12 12v3" /><path d="M18 12v3" /><path d="M15 12v2" /><path d="M3 3v4" /><path d="M3 5h18" /><path d="M21 3v4" /></symbol>' &&
      '<symbol id="wb-icon-schema" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 2h5v4h-5l0 -4" /><path d="M15 10h5v4h-5l0 -4" /><path d="M5 18h5v4h-5l0 -4" /><path d="M5 10h5v4h-5l0 -4" /><path d="M10 12h5" /><path d="M7.5 6v4" /><path d="M7.5 14v4" /></symbol>' &&
      '<symbol id="wb-icon-select" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14" /><path d="M9 11l3 3l3 -3" /></symbol>' &&
      '<symbol id="wb-icon-send" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 14l11 -11" /><path d="M21 3l-6.5 18a.55 .55 0 0 1 -1 0l-3.5 -7l-7 -3.5a.55 .55 0 0 1 0 -1l18 -6.5" /></symbol>' &&
      '<symbol id="wb-icon-server" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3v-2" /><path d="M3 15a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3l0 -2" /><path d="M7 8l0 .01" /><path d="M7 16l0 .01" /></symbol>' &&
      '<symbol id="wb-icon-server-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3v-2" /><path d="M3 15a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3l0 -2" /><path d="M7 8l0 .01" /><path d="M7 16l0 .01" /><path d="M11 8h6" /><path d="M11 16h6" /></symbol>' &&
      '<symbol id="wb-icon-server-cog" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v2a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3v-2" /><path d="M12 20h-6a3 3 0 0 1 -3 -3v-2a3 3 0 0 1 3 -3h10.5" /><path d="M16 18a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M18 14.5v1.5" /><path d="M18 20v1.5" /><path d="M21.032 16.25l-1.299 .75" /><path d="M16.27 19l-1.3 .75" /><path d="M14.97 16.25l1.3 .75" /><path d="M19.733 19l1.3 .75" /><path d="M7 8v.01" /><path d="M7 16v.01" /></symbol>' &&
      '<symbol id="wb-icon-settings-automation" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065" /><path d="M10 9v6l5 -3l-5 -3" /></symbol>' &&
      '<symbol id="wb-icon-share" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M15 6a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M15 18a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M8.7 10.7l6.6 -3.4" /><path d="M8.7 13.3l6.6 3.4" /></symbol>' &&
      '<symbol id="wb-icon-sitemap" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2l0 -2" /><path d="M15 17a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2l0 -2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2l0 -2" /><path d="M6 15v-1a2 2 0 0 1 2 -2h8a2 2 0 0 1 2 2v1" /><path d="M12 9l0 3" /></symbol>' &&
      '<symbol id="wb-icon-sitemap-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2l0 -2" /><path d="M19 15a2 2 0 0 1 2 2m-.591 3.42c-.362 .358 -.86 .58 -1.409 .58h-2a2 2 0 0 1 -2 -2v-2c0 -.549 .221 -1.046 .579 -1.407" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2" /><path d="M6 15v-1a2 2 0 0 1 2 -2h4m4 0a2 2 0 0 1 2 2" /><path d="M3 3l18 18" /></symbol>' &&
      '<symbol id="wb-icon-square-letter-b" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14" /><path d="M10 16h2a2 2 0 1 0 0 -4h-2h2a2 2 0 1 0 0 -4h-2v8" /></symbol>' &&
      '<symbol id="wb-icon-stack-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4l-8 4l8 4l8 -4l-8 -4" /><path d="M4 12l8 4l8 -4" /><path d="M4 16l8 4l8 -4" /></symbol>' &&
      '<symbol id="wb-icon-stack-push" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 10l-2 1l8 4l8 -4l-2 -1" /><path d="M4 15l8 4l8 -4" /><path d="M12 4v7" /><path d="M15 8l-3 3l-3 -3" /></symbol>' &&
      '<symbol id="wb-icon-stairs" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 5h-5v5h-5v5h-5v5h-5" /></symbol>' &&
      '<symbol id="wb-icon-star-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3l18 18" /><path d="M10.012 6.016l1.981 -4.014l3.086 6.253l6.9 1l-4.421 4.304m.012 4.01l.588 3.426l-6.158 -3.245l-6.172 3.245l1.179 -6.873l-5 -4.867l6.327 -.917" /></symbol>' &&
      '<symbol id="wb-icon-switch-horizontal" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 3l4 4l-4 4" /><path d="M10 7l10 0" /><path d="M8 13l-4 4l4 4" /><path d="M4 17l9 0" /></symbol>' &&
      '<symbol id="wb-icon-target" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M7 12a5 5 0 1 0 10 0a5 5 0 1 0 -10 0" /><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /></symbol>' &&
      '<symbol id="wb-icon-template-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 4h11a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-7m-4 0h-3a1 1 0 0 1 -1 -1v-2c0 -.271 .108 -.517 .283 -.697" /><path d="M4 13a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -6" /><path d="M16 12h4" /><path d="M14 16h2" /><path d="M14 20h6" /><path d="M3 3l18 18" /></symbol>' &&
      '<symbol id="wb-icon-test-pipe" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 8.04l-12.122 12.124a2.857 2.857 0 1 1 -4.041 -4.04l12.122 -12.124" /><path d="M7 13h8" /><path d="M19 15l1.5 1.6a2 2 0 1 1 -3 0l1.5 -1.6" /><path d="M15 3l6 6" /></symbol>' &&
      '<symbol id="wb-icon-text-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 10h-14" /><path d="M5 6h14" /><path d="M14 14h-9" /><path d="M5 18h6" /><path d="M18 15v6" /><path d="M15 18h6" /></symbol>' &&
      '<symbol id="wb-icon-thumb-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 13v-8a1 1 0 0 0 -1 -1h-2a1 1 0 0 0 -1 1v7a1 1 0 0 0 1 1h3a4 4 0 0 1 4 4v1a2 2 0 0 0 4 0v-5h3a2 2 0 0 0 2 -2l-1 -5a2 3 0 0 0 -2 -2h-7a3 3 0 0 0 -3 3" /></symbol>' &&
      '<symbol id="wb-icon-thumb-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 11v8a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1v-7a1 1 0 0 1 1 -1h3a4 4 0 0 0 4 -4v-1a2 2 0 0 1 4 0v5h3a2 2 0 0 1 2 2l-1 5a2 3 0 0 1 -2 2h-7a3 3 0 0 1 -3 -3" /></symbol>' &&
      '<symbol id="wb-icon-toggle-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M2 12a6 6 0 0 1 6 -6h8a6 6 0 0 1 6 6a6 6 0 0 1 -6 6h-8a6 6 0 0 1 -6 -6" /></symbol>' &&
      '<symbol id="wb-icon-transfer" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10h-16l5.5 -6" /><path d="M4 14h16l-5.5 6" /></symbol>' &&
      '<symbol id="wb-icon-transform" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /><path d="M21 11v-3a2 2 0 0 0 -2 -2h-6l3 3m0 -6l-3 3" /><path d="M3 13v3a2 2 0 0 0 2 2h6l-3 -3m0 6l3 -3" /><path d="M15 18a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /></symbol>' &&
      '<symbol id="wb-icon-trending-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7l6 6l4 -4l8 8" /><path d="M21 10l0 7l-7 0" /></symbol>' &&
      '<symbol id="wb-icon-trending-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17l6 -6l4 4l8 -8" /><path d="M14 7l7 0l0 7" /></symbol>' &&
      '<symbol id="wb-icon-truck-delivery" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M15 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M5 17h-2v-4m-1 -8h11v12m-4 0h6m4 0h2v-6h-8m0 -5h5l3 5" /><path d="M3 9l4 0" /></symbol>' &&
      '<symbol id="wb-icon-unlink" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 22v-2" /><path d="M9 15l6 -6" /><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464" /><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463" /><path d="M20 17h2" /><path d="M2 7h2" /><path d="M7 2v2" /></symbol>' &&
      '<symbol id="wb-icon-user-cog" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h2.5" /><path d="M17.001 19a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M19.001 15.5v1.5" /><path d="M19.001 21v1.5" /><path d="M22.032 17.25l-1.299 .75" /><path d="M17.27 20l-1.3 .75" /><path d="M15.97 17.25l1.3 .75" /><path d="M20.733 20l1.3 .75" /></symbol>' &&
      '<symbol id="wb-icon-user-dollar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h3" /><path d="M21 15h-2.5a1.5 1.5 0 0 0 0 3h1a1.5 1.5 0 0 1 0 3h-2.5" /><path d="M19 21v1m0 -8v1" /></symbol>' &&
      '<symbol id="wb-icon-user-pause" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h3.5" /><path d="M17 17v5" /><path d="M21 17v5" /></symbol>' &&
      '<symbol id="wb-icon-user-square" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 10a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /><path d="M6 21v-1a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v1" /><path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14" /></symbol>' &&
      '<symbol id="wb-icon-users" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 7a4 4 0 1 0 8 0a4 4 0 1 0 -8 0" /><path d="M3 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /><path d="M21 21v-2a4 4 0 0 0 -3 -3.85" /></symbol>' &&
      '<symbol id="wb-icon-users-group" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M8 21v-1a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v1" /><path d="M15 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M17 10h2a2 2 0 0 1 2 2v1" /><path d="M5 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M3 13v-1a2 2 0 0 1 2 -2h2" /></symbol>' &&
      '<symbol id="wb-icon-variable" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 4c-2.5 5 -2.5 10 0 16m14 -16c2.5 5 2.5 10 0 16m-10 -11h1c1 0 1 1 2.016 3.527c.984 2.473 .984 3.473 1.984 3.473h1" /><path d="M8 16c1.5 0 3 -2 4 -3.5s2.5 -3.5 4 -3.5" /></symbol>' &&
      '<symbol id="wb-icon-video" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 10l4.553 -2.276a1 1 0 0 1 1.447 .894v6.764a1 1 0 0 1 -1.447 .894l-4.553 -2.276v-4" /><path d="M3 8a2 2 0 0 1 2 -2h8a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2l0 -8" /></symbol>' &&
      '<symbol id="wb-icon-world" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M3.6 9h16.8" /><path d="M3.6 15h16.8" /><path d="M11.5 3a17 17 0 0 0 0 18" /><path d="M12.5 3a17 17 0 0 1 0 18" /></symbol>' &&
      '<symbol id="wb-icon-zoom-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" /><path d="M7 10l2 2l4 -4" /></symbol>' &&
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
