CLASS zcl_gg_plan9_examples_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared, server-owned examples for the post-151 GUI contracts. The examples
* intentionally use the public control model and the typed host surface; the
* browser never receives an application-owned state machine or raw HTML.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.
    DATA mv_started TYPE abap_bool.
    DATA mv_running TYPE abap_bool.
    DATA mv_ticks TYPE i.
    DATA mv_interval TYPE i.
    DATA mv_timer_instance TYPE i.
    DATA mv_location TYPE string.
    DATA mv_effect TYPE string.
    DATA mv_reject_next TYPE abap_bool.
    DATA mv_undo_available TYPE abap_bool.
    DATA mv_uploaded TYPE abap_bool.
    DATA mv_downloaded TYPE abap_bool.
    DATA mv_clipboard TYPE abap_bool.
    DATA mv_dialog_open TYPE abap_bool.
    DATA mv_dialog_left TYPE i.
    DATA mv_dialog_top TYPE i.
    DATA mv_dialog_width TYPE i.
    DATA mv_dialog_height TYPE i.
    DATA mv_popup_kind TYPE string.
    DATA mv_popup_result TYPE string.
    DATA mv_variant TYPE string.
    DATA mv_variant_saved TYPE abap_bool.
    DATA mv_variant_layout TYPE string.
    DATA mv_month_offset TYPE i.

    METHODS build_view
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.

    METHODS clear_view.

    METHODS set_status
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.

    METHODS write_line
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_text    TYPE string.

    METHODS action_status
      RETURNING
        VALUE(rv_status) TYPE string.

    METHODS mode_title
      RETURNING
        VALUE(rv_title) TYPE string.
ENDCLASS.

CLASS zcl_gg_plan9_examples_base IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
    mv_interval = 1000.
    mv_location = 'Source row 1'.
    mv_effect = 'move'.
    mv_dialog_left = 80.
    mv_dialog_top = 40.
    mv_dialog_width = 360.
    mv_dialog_height = 180.
    mv_variant = 'DEFAULT'.
    mv_variant_layout = 'Carrier, Flight, Seats'.
  ENDMETHOD.

  METHOD mode_title.
    CASE mv_mode.
      WHEN '152'.
        rv_title = 'Timer lifecycle'.
      WHEN '153'.
        rv_title = 'Tree and grid drag and drop'.
      WHEN '154'.
        rv_title = 'Browser frontend services'.
      WHEN '155'.
        rv_title = 'Modeless dialog container'.
      WHEN '156'.
        rv_title = 'Popup compatibility gallery'.
      WHEN '157'.
        rv_title = 'ALV variant lifecycle'.
      WHEN '158'.
        rv_title = 'Hierarchical-sequential SALV'.
      WHEN '159'.
        rv_title = 'Multi-month calendar'.
      WHEN OTHERS.
        rv_title = |PLAN9 example { mv_mode }|.
    ENDCASE.
  ENDMETHOD.

  METHOD write_line.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = iv_text
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD action_status.
    CASE mv_mode.
      WHEN '152'.
        rv_status = COND string( WHEN mv_running = abap_true THEN 'TIMER RUNNING' ELSE 'TIMER STOPPED' ).
      WHEN '153'.
        rv_status = COND string( WHEN mv_reject_next = abap_true THEN 'REJECT NEXT DROP' ELSE |{ mv_effect } to { mv_location }| ).
      WHEN '154'.
        rv_status = 'BROWSER CAPABILITIES'.
      WHEN '155'.
        rv_status = COND string( WHEN mv_dialog_open = abap_true THEN 'DIALOG OPEN' ELSE 'DIALOG CLOSED' ).
      WHEN '156'.
        rv_status = COND string( WHEN mv_popup_kind IS INITIAL THEN 'POPUP GALLERY' ELSE |{ mv_popup_kind } OPEN| ).
      WHEN '157'.
        rv_status = COND string( WHEN mv_variant_saved = abap_true THEN |VARIANT { mv_variant } SAVED| ELSE 'ALV LAYOUT READY' ).
      WHEN '158'.
        rv_status = 'SALV HIERSEQ READY'.
      WHEN '159'.
        rv_status = |CALENDAR WINDOW { mv_month_offset + 1 }|.
    ENDCASE.
  ENDMETHOD.

  METHOD set_status.
    DATA ls_status TYPE zif_gg_session_types_v1=>ty_gui_status.

    ls_status-status = action_status( ).
    CASE mv_mode.
      WHEN '152'.
        ls_status-active_ucomm = VALUE #( ( 'START_TIMER' ) ( 'STOP_TIMER' ) ( 'TICK_TIMER' )
          ( 'FASTER' ) ( 'SLOWER' ) ( 'REUSE_TIMER' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'START_TIMER' label = 'Start timer' icon = 'play' )
          ( ucomm = 'STOP_TIMER' label = 'Stop timer' icon = 'stop' )
          ( ucomm = 'TICK_TIMER' label = 'Tick once' icon = 'refresh' )
          ( ucomm = 'FASTER' label = 'Faster interval' icon = 'arrow-up' )
          ( ucomm = 'SLOWER' label = 'Slower interval' icon = 'arrow-down' )
          ( ucomm = 'REUSE_TIMER' label = 'Reuse instance' icon = 'refresh' ) ).
      WHEN '153'.
        ls_status-active_ucomm = VALUE #( ( 'MOVE_NODE' ) ( 'COPY_NODE' ) ( 'KEYBOARD_MOVE' )
          ( 'REJECT_NEXT' ) ( 'UNDO_DROP' ) ( 'INSPECT_PAYLOAD' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'MOVE_NODE' label = 'Move node' icon = 'arrow-right' )
          ( ucomm = 'COPY_NODE' label = 'Copy node' icon = 'copy' )
          ( ucomm = 'KEYBOARD_MOVE' label = 'Keyboard move' icon = 'arrow-right' )
          ( ucomm = 'REJECT_NEXT' label = 'Reject next drop' icon = 'warning' )
          ( ucomm = 'UNDO_DROP' label = 'Undo drop' icon = 'undo' )
          ( ucomm = 'INSPECT_PAYLOAD' label = 'Inspect payload' icon = 'display' ) ).
      WHEN '154'.
        ls_status-active_ucomm = VALUE #( ( 'UPLOAD' ) ( 'DOWNLOAD' ) ( 'CLIPBOARD' )
          ( 'OPEN_URL' ) ( 'DIRECTORY' ) ( 'REGISTRY' ) ( 'CLEANUP' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'UPLOAD' label = 'Choose upload' icon = 'upload' )
          ( ucomm = 'DOWNLOAD' label = 'Download sample' icon = 'download' )
          ( ucomm = 'CLIPBOARD' label = 'Clipboard permission' icon = 'copy' )
          ( ucomm = 'OPEN_URL' label = 'Open safe URL' icon = 'link' )
          ( ucomm = 'DIRECTORY' label = 'Directory capability' icon = 'folder' )
          ( ucomm = 'REGISTRY' label = 'Registry capability' icon = 'warning' )
          ( ucomm = 'CLEANUP' label = 'Cleanup sample data' icon = 'delete' ) ).
      WHEN '155'.
        ls_status-active_ucomm = VALUE #( ( 'MOVE_DIALOG' ) ( 'RESIZE_DIALOG' )
          ( 'FOCUS_DIALOG' ) ( 'PARENT_ACTION' ) ( 'CLOSE_DIALOG' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'MOVE_DIALOG' label = 'Move dialog' icon = 'arrow-right' )
          ( ucomm = 'RESIZE_DIALOG' label = 'Resize dialog' icon = 'expand' )
          ( ucomm = 'FOCUS_DIALOG' label = 'Focus dialog' icon = 'focus' )
          ( ucomm = 'PARENT_ACTION' label = 'Use parent' icon = 'arrow-left' )
          ( ucomm = 'CLOSE_DIALOG' label = 'Close dialog' icon = 'circle-x' ) ).
      WHEN '156'.
        ls_status-active_ucomm = VALUE #( ( 'OPEN_CONFIRM' ) ( 'OPEN_INPUT' ) ( 'OPEN_SELECTION' )
          ( 'OPEN_MESSAGE' ) ( 'OPEN_PROGRESS' ) ( 'POPUP_OK' ) ( 'POPUP_CANCEL' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'OPEN_CONFIRM' label = 'Confirm popup' icon = 'question' )
          ( ucomm = 'OPEN_INPUT' label = 'Input popup' icon = 'edit' )
          ( ucomm = 'OPEN_SELECTION' label = 'Selection popup' icon = 'select-all' )
          ( ucomm = 'OPEN_MESSAGE' label = 'Message popup' icon = 'information' )
          ( ucomm = 'OPEN_PROGRESS' label = 'Progress popup' icon = 'refresh' ) ).
      WHEN '157'.
        ls_status-active_ucomm = VALUE #( ( 'SAVE_VARIANT' ) ( 'APPLY_VARIANT' ) ( 'SWITCH_VARIANT' )
          ( 'DELETE_VARIANT' ) ( 'CLEANUP_VARIANT' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'SAVE_VARIANT' label = 'Save layout' icon = 'save' )
          ( ucomm = 'APPLY_VARIANT' label = 'Apply layout' icon = 'check' )
          ( ucomm = 'SWITCH_VARIANT' label = 'Switch layout' icon = 'refresh' )
          ( ucomm = 'DELETE_VARIANT' label = 'Delete layout' icon = 'delete' )
          ( ucomm = 'CLEANUP_VARIANT' label = 'Cleanup layouts' icon = 'delete' ) ).
      WHEN '158'.
        ls_status-active_ucomm = VALUE #( ( 'SORT_HIERSEQ' ) ( 'SELECT_HIERSEQ' ) ( 'SHOW_TOTALS' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'SORT_HIERSEQ' label = 'Sort hierarchy' icon = 'sort' )
          ( ucomm = 'SELECT_HIERSEQ' label = 'Select item' icon = 'select-all' )
          ( ucomm = 'SHOW_TOTALS' label = 'Show totals' icon = 'sum' ) ).
      WHEN '159'.
        ls_status-active_ucomm = VALUE #( ( 'PREVIOUS_MONTHS' ) ( 'NEXT_MONTHS' )
          ( 'TODAY' ) ( 'SET_DATE' ) ( 'MARK_DATE' ) ( 'CLEAR_DATE' ) ( 'RECREATE' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'PREVIOUS_MONTHS' label = 'Previous months' icon = 'arrow-left' )
          ( ucomm = 'NEXT_MONTHS' label = 'Next months' icon = 'arrow-right' )
          ( ucomm = 'TODAY' label = 'Today' icon = 'calendar' )
          ( ucomm = 'SET_DATE' label = 'Set date' icon = 'check' )
          ( ucomm = 'MARK_DATE' label = 'Mark date' icon = 'star' )
          ( ucomm = 'CLEAR_DATE' label = 'Clear marks' icon = 'delete' )
          ( ucomm = 'RECREATE' label = 'Recreate calendar' icon = 'refresh' ) ).
    ENDCASE.
    io_session->get_list( )->set_status( ls_status ).
  ENDMETHOD.

  METHOD build_view.
    DATA ls_surface TYPE zcl_gg_host_surface=>ty_surface.
    DATA lo_root TYPE REF TO cl_gui_custom_container.
    DATA lt_nodes TYPE string_table.
    DATA lt_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.

    CASE mv_mode.
      WHEN '152'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT152' ).
        DATA(lo_timer) = NEW cl_gui_timer( ).
        cl_gui_control=>initialize( control = lo_timer
                                    parent  = lo_root
                                    kind    = 'TIMER' ).
        lo_root->add_child( lo_timer ).
        IF mv_running = abap_true.
          lo_timer->run( ).
        ENDIF.
        ls_surface = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Timer lifecycle state'
          table_caption = 'Session-owned timer'
          columns       = VALUE #( ( `Property` ) ( `Value` ) ( `Scope` ) )
          rows          = VALUE #(
            ( cell1 = 'Running' cell2 = COND string( WHEN mv_running = abap_true THEN 'yes' ELSE 'no' ) cell3 = 'current session' )
            ( cell1 = 'Interval (ms)' cell2 = |{ mv_interval }| cell3 = 'server state' )
            ( cell1 = 'Completed ticks' cell2 = |{ mv_ticks }| cell3 = 'deterministic clock' )
            ( cell1 = 'Timer instance' cell2 = |{ mv_timer_instance }| cell3 = 'reusable' ) )
          text          = 'Tick once advances the deterministic test clock; no background browser timer is fabricated.' ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '153'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT153' ).
        DATA(lo_tree) = NEW cl_gui_simple_tree( parent = lo_root ).
        lt_nodes = VALUE #( ( `Orders` ) ( `Order 100` ) ( `Order 200` ) ).
        lo_tree->add_nodes( table_structure_name = 'TREEV_NODE'
                            node_table           = lt_nodes ).
        APPEND 'Lufthansa' TO lt_rows.
        APPEND 'United' TO lt_rows.
        APPEND VALUE #( fieldname = 'CARRIER' coltext = 'Grid row' outputlen = 20 ) TO lt_fcat.
        DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_root ).
        lo_grid->set_table_for_first_display( CHANGING it_outtab = lt_rows it_fieldcatalog = lt_fcat ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind        = zcl_gg_host_surface=>surface_tree
          aria_label  = 'Drag source tree'
          nodes       = VALUE #(
            ( text = 'Orders' level = 1 node_key = 'NODE-ROOT' expanded = abap_true )
            ( text = 'Order 100' level = 2 node_key = 'NODE-100' selected = abap_true )
            ( text = 'Order 200' level = 2 node_key = 'NODE-200' ) )
          token_label = 'Opaque drag token'
          token_value = 'DD-SESSION-NODE-100'
          actions     = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'MOVE_NODE' label = 'Drop as move' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'COPY_NODE' label = 'Drop as copy' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'REJECT_NEXT' label = 'Reject next drop' ) ) ) ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Drag target grid'
          table_caption = 'Drop target grid'
          columns       = VALUE #( ( `Row` ) ( `Destination` ) ( `Effect` ) )
          rows          = VALUE #( ( cell1 = '1' cell2 = mv_location cell3 = mv_effect row_header = abap_true )
                          ( cell1 = '2' cell2 = 'Archive' cell3 = 'available' ) )
          text          = COND string( WHEN mv_undo_available = abap_true THEN 'Undo is available for the last accepted drop.' ELSE 'Use keyboard actions when pointer drag is unavailable.' ) ) ).
      WHEN '154'.
        ls_surface = VALUE #(
          kind        = zcl_gg_host_surface=>surface_document
          aria_label  = 'Browser frontend capability report'
          title       = 'Explicit browser capabilities'
          text        = 'Desktop-only operations are refused or require a real browser permission. The host never claims a file, clipboard, directory, registry, or URL operation happened without evidence.'
          input_label = 'Upload fixture'
          input_name  = 'UPLOAD_FILE'
          input_type  = 'file'
          actions     = VALUE #(
            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'UPLOAD' label = 'Inspect upload' )
            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DOWNLOAD' label = 'Prepare download' )
            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CLIPBOARD' label = 'Request clipboard' )
            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_URL' label = 'Open safe URL' )
            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DIRECTORY' label = 'Directory check' )
            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'REGISTRY' label = 'Registry check' )
            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CLEANUP' label = 'Cleanup sample data' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Frontend capability results'
          table_caption = 'Auditable result'
          columns       = VALUE #( ( `Operation` ) ( `Result` ) ( `Reason` ) )
          rows          = VALUE #(
            ( cell1 = 'Upload' cell2 = COND string( WHEN mv_uploaded = abap_true THEN 'inspected' ELSE 'not requested' ) cell3 = 'bytes remain browser-owned' )
            ( cell1 = 'Download' cell2 = COND string( WHEN mv_downloaded = abap_true THEN 'prepared' ELSE 'not requested' ) cell3 = 'user activation required' )
            ( cell1 = 'Clipboard' cell2 = COND string( WHEN mv_clipboard = abap_true THEN 'permission requested' ELSE 'not requested' ) cell3 = 'permission is explicit' )
            ( cell1 = 'Directory / registry' cell2 = 'refused' cell3 = 'desktop API unavailable' ) ) ) ).
      WHEN '155'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT155' ).
        IF mv_dialog_open = abap_true.
          DATA(lo_dialog) = NEW cl_gui_dialogbox_container( parent   = lo_root
                                                             width   = mv_dialog_width
                                                             height  = mv_dialog_height
                                                             top     = mv_dialog_top
                                                             left    = mv_dialog_left
                                                             caption = 'Modeless dialog' ).
          DATA(lo_dialog_editor) = NEW cl_gui_textedit( parent                     = lo_dialog
                                                        wordwrap_to_linebreak_mode = 0 ).
          lo_dialog_editor->set_textstream( 'The parent remains available while this modeless dialog is open.' ).
        ENDIF.
        ls_surface = VALUE #(
          kind          = zcl_gg_host_surface=>surface_document
          aria_label    = 'Modeless dialog lifecycle'
          title         = 'Modeless dialog lifecycle'
          text          = COND string( WHEN mv_dialog_open = abap_true THEN 'Dialog is independent of the parent surface.' ELSE 'Dialog closed; parent surface remains usable.' )
          table_caption = 'Dialog geometry'
          columns       = VALUE #( ( `Property` ) ( `Value` ) )
          rows          = VALUE #( ( cell1 = 'Position' cell2 = |{ mv_dialog_left }, { mv_dialog_top }| )
                          ( cell1 = 'Size' cell2 = |{ mv_dialog_width } x { mv_dialog_height }| ) )
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'MOVE_DIALOG' label = 'Move' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RESIZE_DIALOG' label = 'Resize' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'FOCUS_DIALOG' label = 'Focus dialog' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PARENT_ACTION' label = 'Parent action' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CLOSE_DIALOG' label = 'Close' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '156'.
        ls_surface = VALUE #(
          kind       = zcl_gg_host_surface=>surface_document
          aria_label = 'Popup compatibility gallery'
          title      = 'Typed popup compatibility gallery'
          text       = COND string( WHEN mv_popup_result IS INITIAL THEN 'Open a popup family and close it to record its typed return.' ELSE mv_popup_result )
          actions    = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_CONFIRM' label = 'Confirm' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_INPUT' label = 'Input' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_SELECTION' label = 'Selection' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_MESSAGE' label = 'Message' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_PROGRESS' label = 'Progress' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
        IF mv_popup_kind IS NOT INITIAL.
          DATA(lv_popup_text) = COND string(
            WHEN mv_popup_kind = 'CONFIRM' THEN 'Confirm this server-owned action.'
            WHEN mv_popup_kind = 'INPUT' THEN 'Enter a value; the result is returned as text.'
            WHEN mv_popup_kind = 'SELECTION' THEN 'Select one of the available values.'
            WHEN mv_popup_kind = 'MESSAGE' THEN 'This is an informational message.'
            ELSE 'Progress is reported without blocking the browser.' ).
          zcl_gg_host_surface=>set_surface( VALUE #(
            kind        = zcl_gg_host_surface=>surface_popup
            aria_label  = |{ mv_popup_kind } popup|
            title       = |{ mv_popup_kind } popup|
            text        = lv_popup_text
            input_label = COND string( WHEN mv_popup_kind = 'INPUT' THEN 'Value' ELSE '' )
            input_name  = COND string( WHEN mv_popup_kind = 'INPUT' THEN 'POPUP_VALUE' ELSE '' )
            actions     = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_OK' label = 'OK' )
                               ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_CANCEL' label = 'Cancel' ) ) ) ).
        ENDIF.
      WHEN '157'.
        ls_surface = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'ALV variant lifecycle'
          table_caption = 'Server-owned ALV layout'
          columns       = VALUE #( ( `Carrier` ) ( `Flight` ) ( `Seats` ) )
          rows          = VALUE #( ( cell1 = 'Lufthansa' cell2 = 'LH400' cell3 = '180' )
                          ( cell1 = 'United' cell2 = 'UA901' cell3 = '210' )
                          ( cell1 = 'Air France' cell2 = 'AF010' cell3 = '160' ) )
          input_label   = 'Variant name'
          input_name    = 'ALV_VARIANT'
          input_value   = mv_variant
          text          = |Layout: { mv_variant_layout }. Handles are report-local; no database persistence is implied.| ).
        ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SAVE_VARIANT' label = 'Save' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'APPLY_VARIANT' label = 'Apply' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SWITCH_VARIANT' label = 'Switch' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DELETE_VARIANT' label = 'Delete' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CLEANUP_VARIANT' label = 'Cleanup' ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '158'.
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Hierarchical sequential SALV'
          table_caption = 'Header and item relations'
          columns       = VALUE #( ( `Level` ) ( `Description` ) ( `Quantity` ) ( `Price` ) )
          rows          = VALUE #(
            ( cell1 = 'Header' cell2 = 'Order 100' cell3 = '-' cell4 = '-' row_header = abap_true )
            ( cell1 = 'Item' cell2 = 'LH400 / Lufthansa' cell3 = '2' cell4 = '120.00 EUR' )
            ( cell1 = 'Item' cell2 = 'LH401 / Lufthansa' cell3 = '1' cell4 = '80.00 EUR' )
            ( cell1 = 'Header' cell2 = 'Order 200' cell3 = '-' cell4 = '-' row_header = abap_true )
            ( cell1 = 'Item' cell2 = 'UA901 / United' cell3 = '3' cell4 = '210.00 USD' ) )
          data_value    = COND string( WHEN mv_ticks > 0 THEN 'Total: 410.00 (typed header/item total)' ELSE 'Total: 410.00' )
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SORT_HIERSEQ' label = 'Sort items' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SELECT_HIERSEQ' label = 'Select item' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SHOW_TOTALS' label = 'Show totals' ) ) ) ).
      WHEN '159'.
        DATA(lv_first_month) = COND string( WHEN mv_month_offset = 0 THEN '2026-08' ELSE '2026-11' ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Nine month calendar'
          table_caption = |Nine-month calendar from { lv_first_month }|
          columns       = VALUE #( ( `Month` ) ( `ISO weeks` ) ( `Focus` ) ( `Marks` ) )
          rows          = VALUE #( ( cell1 = '2026-08' cell2 = '31-35' cell3 = COND string( WHEN mv_month_offset = 0 THEN '2026-08-30' ELSE '' ) cell4 = '1' )
                          ( cell1 = '2026-09' cell2 = '36-39' cell3 = '' cell4 = '0' )
                          ( cell1 = '2026-10' cell2 = '40-44' cell3 = '' cell4 = '0' )
                          ( cell1 = '2026-11' cell2 = '45-48' cell3 = COND string( WHEN mv_month_offset = 1 THEN '2026-11-13' ELSE '' ) cell4 = '0' )
                          ( cell1 = '2026-12' cell2 = '49-53' cell3 = '' cell4 = '0' )
                          ( cell1 = '2027-01' cell2 = '01-04' cell3 = '' cell4 = '0' )
                          ( cell1 = '2027-02' cell2 = '05-08' cell3 = '' cell4 = '0' )
                          ( cell1 = '2027-03' cell2 = '09-13' cell3 = '' cell4 = '0' )
                          ( cell1 = '2027-04' cell2 = '14-17' cell3 = '' cell4 = '0' ) )
          text          = 'Week numbers, focus, selection, and marks are deterministic and locale-stable.'
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PREVIOUS_MONTHS' label = 'Previous' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'NEXT_MONTHS' label = 'Next' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'TODAY' label = 'Today' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SET_DATE' label = 'Set date' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'MARK_DATE' label = 'Mark date' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CLEAR_DATE' label = 'Clear marks' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RECREATE' label = 'Recreate' ) ) ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD clear_view.
    cl_gui_control=>clear( ).
    zcl_gg_host_surface=>clear( ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    IF mv_started = abap_false.
      mv_started = abap_true.
      IF mv_mode = '155'.
        mv_dialog_open = abap_true.
      ENDIF.
    ENDIF.
    io_session->get_list( )->set_title( mode_title( ) ).
    set_status( io_session ).
    build_view( io_session ).
    write_line( io_session = io_session
                iv_text    = |Server-owned { mode_title( ) } state| ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    clear_view( ).
    CASE mv_mode.
      WHEN '152'.
        CASE iv_ucomm.
          WHEN 'START_TIMER'.
            mv_running = abap_true.
          WHEN 'STOP_TIMER'.
            mv_running = abap_false.
          WHEN 'TICK_TIMER'.
            IF mv_running = abap_true.
              mv_ticks = mv_ticks + 1.
            ENDIF.
          WHEN 'FASTER'.
            mv_interval = COND #( WHEN mv_interval > 100 THEN mv_interval - 100 ELSE 100 ).
          WHEN 'SLOWER'.
            mv_interval = mv_interval + 100.
          WHEN 'REUSE_TIMER'.
            mv_timer_instance = mv_timer_instance + 1.
            mv_ticks = 0.
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
        write_line( io_session = io_session
                    iv_text    = |Timer action { iv_ucomm } accepted; ticks={ mv_ticks }, interval={ mv_interval }| ).
      WHEN '153'.
        CASE iv_ucomm.
          WHEN 'MOVE_NODE' OR 'KEYBOARD_MOVE'.
            IF mv_reject_next = abap_true.
              mv_reject_next = abap_false.
              write_line( io_session = io_session
                          iv_text    = 'Drop rejected by server validation; no row changed' ).
            ELSE.
              mv_location = 'Grid row 2'.
              mv_effect = 'move'.
              mv_undo_available = abap_true.
              write_line( io_session = io_session
                          iv_text    = 'Accepted move for opaque NODE-100 token' ).
            ENDIF.
          WHEN 'COPY_NODE'.
            IF mv_reject_next = abap_true.
              mv_reject_next = abap_false.
              write_line( io_session = io_session
                          iv_text    = 'Copy rejected by server validation; no row changed' ).
            ELSE.
              mv_location = 'Grid row 2 (copy)'.
              mv_effect = 'copy'.
              mv_undo_available = abap_true.
              write_line( io_session = io_session
                          iv_text    = 'Accepted copy for opaque NODE-100 token' ).
            ENDIF.
          WHEN 'REJECT_NEXT'.
            mv_reject_next = abap_true.
            write_line( io_session = io_session
                        iv_text    = 'The next drop will be rejected' ).
          WHEN 'UNDO_DROP'.
            IF mv_undo_available = abap_true.
              mv_location = 'Source row 1'.
              mv_effect = 'move'.
              mv_undo_available = abap_false.
              write_line( io_session = io_session
                          iv_text    = 'Last drop undone' ).
            ELSE.
              write_line( io_session = io_session
                          iv_text    = 'No accepted drop is available to undo' ).
            ENDIF.
          WHEN 'INSPECT_PAYLOAD'.
            write_line( io_session = io_session
                        iv_text    = 'Payload NODE-100; flavor=application/x-gg-row; effect validated server-side' ).
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
      WHEN '154'.
        CASE iv_ucomm.
          WHEN 'UPLOAD'.
            mv_uploaded = abap_true.
            write_line( io_session = io_session
                        iv_text    = 'Upload metadata inspected; browser bytes were not claimed by the server' ).
          WHEN 'DOWNLOAD'.
            mv_downloaded = abap_true.
            write_line( io_session = io_session
                        iv_text    = 'Download prepared; browser must perform the user-activated transfer' ).
          WHEN 'CLIPBOARD'.
            mv_clipboard = abap_true.
            write_line( io_session = io_session
                        iv_text    = 'Clipboard permission is explicit; no clipboard contents were fabricated' ).
          WHEN 'OPEN_URL'.
            write_line( io_session = io_session
                        iv_text    = 'Opened only the allow-listed sample URL https://open-abap.invalid/' ).
          WHEN 'DIRECTORY'.
            write_line( io_session = io_session
                        iv_text    = 'Directory access refused: browser has no desktop directory capability' ).
          WHEN 'REGISTRY'.
            write_line( io_session = io_session
                        iv_text    = 'Registry access refused: browser has no operating-system registry capability' ).
          WHEN 'CLEANUP'.
            mv_uploaded = abap_false.
            mv_downloaded = abap_false.
            mv_clipboard = abap_false.
            write_line( io_session = io_session
                        iv_text    = 'Sample-owned temporary state cleaned up' ).
        ENDCASE.
        build_view( io_session ).
      WHEN '155'.
        CASE iv_ucomm.
          WHEN 'MOVE_DIALOG'.
            mv_dialog_left = mv_dialog_left + 20.
            mv_dialog_top = mv_dialog_top + 10.
          WHEN 'RESIZE_DIALOG'.
            mv_dialog_width = mv_dialog_width + 20.
            mv_dialog_height = mv_dialog_height + 10.
          WHEN 'FOCUS_DIALOG'.
            write_line( io_session = io_session
                        iv_text    = 'Modeless dialog focus restored without blocking the parent' ).
          WHEN 'PARENT_ACTION'.
            write_line( io_session = io_session
                        iv_text    = 'Parent action remained available while dialog was modeless' ).
          WHEN 'CLOSE_DIALOG'.
            mv_dialog_open = abap_false.
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
      WHEN '156'.
        CASE iv_ucomm.
          WHEN 'OPEN_CONFIRM'.
            mv_popup_kind = 'CONFIRM'.
          WHEN 'OPEN_INPUT'.
            mv_popup_kind = 'INPUT'.
          WHEN 'OPEN_SELECTION'.
            mv_popup_kind = 'SELECTION'.
          WHEN 'OPEN_MESSAGE'.
            mv_popup_kind = 'MESSAGE'.
          WHEN 'OPEN_PROGRESS'.
            mv_popup_kind = 'PROGRESS'.
          WHEN 'POPUP_OK'.
            mv_popup_result = |{ mv_popup_kind } returned typed OK|.
            CLEAR mv_popup_kind.
          WHEN 'POPUP_CANCEL'.
            mv_popup_result = |{ mv_popup_kind } cancelled with return code 1|.
            CLEAR mv_popup_kind.
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
      WHEN '157'.
        CASE iv_ucomm.
          WHEN 'SAVE_VARIANT'.
            mv_variant_saved = abap_true.
            mv_variant_layout = 'Carrier, Flight, Seats (saved)'.
          WHEN 'APPLY_VARIANT'.
            IF mv_variant_saved = abap_true.
              mv_variant_layout = 'Carrier, Flight, Seats (applied)'.
            ENDIF.
          WHEN 'SWITCH_VARIANT'.
            mv_variant = COND string( WHEN mv_variant = 'DEFAULT' THEN 'COMPACT' ELSE 'DEFAULT' ).
          WHEN 'DELETE_VARIANT'.
            mv_variant_saved = abap_false.
            mv_variant_layout = 'Carrier, Flight, Seats'.
          WHEN 'CLEANUP_VARIANT'.
            mv_variant_saved = abap_false.
            mv_variant = 'DEFAULT'.
            mv_variant_layout = 'Carrier, Flight, Seats'.
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
        write_line( io_session = io_session
                    iv_text    = |ALV variant action { iv_ucomm } completed in report-local memory| ).
      WHEN '158'.
        CASE iv_ucomm.
          WHEN 'SORT_HIERSEQ'.
            mv_ticks = mv_ticks + 1.
          WHEN 'SELECT_HIERSEQ'.
            write_line( io_session = io_session
                        iv_text    = 'Selected item LH400 under header Order 100' ).
          WHEN 'SHOW_TOTALS'.
            mv_ticks = mv_ticks + 1.
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
      WHEN '159'.
        CASE iv_ucomm.
          WHEN 'PREVIOUS_MONTHS'.
            mv_month_offset = 0.
          WHEN 'NEXT_MONTHS'.
            mv_month_offset = 1.
          WHEN 'TODAY'.
            mv_month_offset = 0.
          WHEN 'SET_DATE'.
            write_line( io_session = io_session
                        iv_text    = 'Selected 2026-08-30' ).
          WHEN 'MARK_DATE'.
            write_line( io_session = io_session
                        iv_text    = 'Marked 2026-08-30' ).
          WHEN 'CLEAR_DATE'.
            write_line( io_session = io_session
                        iv_text    = 'Calendar marks cleared' ).
          WHEN 'RECREATE'.
            mv_month_offset = 0.
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    rs_settings = VALUE #( title = mode_title( ) status = action_status( ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_end_of.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_radio.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_exit.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get_late.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~end_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
