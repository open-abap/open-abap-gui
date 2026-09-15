CLASS zcl_gg_plan9_examples_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared, server-owned examples for the post-151 GUI contracts. The examples
* intentionally use the public control model and the typed host surface; the
* browser never receives an application-owned state machine or raw HTML.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.
    INTERFACES zif_gg_session_lifecycle_v1.

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
    DATA mv_dialog_focus TYPE abap_bool.
    DATA mv_dialog_event TYPE string.
    DATA mv_popup_kind TYPE string.
    DATA mv_popup_result TYPE string.
    DATA mt_popup_log TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA mv_variant TYPE string.
    DATA mv_variant_saved TYPE abap_bool.
    DATA mv_variant_layout TYPE string.
    DATA mv_variant_pending TYPE abap_bool.
    DATA mv_variant_owner TYPE string.
    DATA mv_variant_handle TYPE string.
    DATA mv_variant_message TYPE string.
    DATA mv_month_offset TYPE i.
    DATA mv_calendar_date159 TYPE string.
    DATA mv_calendar_range159 TYPE abap_bool.
    DATA mv_calendar_marked159 TYPE abap_bool.
    DATA mv_calendar_generation159 TYPE i.
    DATA mv_calendar_event159 TYPE string.
    DATA mo_timer TYPE REF TO cl_gui_timer.

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

    METHODS request_value
      IMPORTING
        io_session      TYPE REF TO zif_gg_session_v1
        iv_name         TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS handle_calendar_command
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_ucomm   TYPE zif_gg_list_processing_types_v1=>ty_ucomm.

    METHODS stop_session_resources.

    METHODS action_status
      RETURNING
        VALUE(rv_status) TYPE string.

    METHODS valid_variant_name
      IMPORTING
        iv_name         TYPE string
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    METHODS build_salv_hierseq.

    METHODS handle_variant_command
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_ucomm   TYPE zif_gg_list_processing_types_v1=>ty_ucomm.

    METHODS handle_hierseq_command
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_ucomm   TYPE zif_gg_list_processing_types_v1=>ty_ucomm.

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
    mv_dialog_event = 'OPEN'.
    mv_variant = 'DEFAULT'.
    mv_variant_layout = 'Carrier, Flight, Seats'.
    mv_variant_owner = 'GG_EX_157'.
    mv_variant_handle = 'ALV-VAR-157'.
    mv_variant_message = 'No variant action has been committed'.
    mv_calendar_date159 = '2026-08-30'.
    mv_calendar_marked159 = abap_true.
    mv_calendar_generation159 = 1.
    mv_calendar_event159 = 'INITIALIZED'.
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

  METHOD request_value.
    DATA lo_host_session TYPE REF TO zcl_gg_host_session.
    TRY.
        lo_host_session ?= io_session.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lo_host_session IS BOUND.
      rv_value = lo_host_session->get_request_value( iv_name ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_calendar_command.
    DATA(lv_requested_date) = request_value( io_session = io_session
                                             iv_name    = 'CALENDAR_DATE' ).
    CASE iv_ucomm.
      WHEN 'PREVIOUS_MONTHS'.
        mv_month_offset = 0.
        mv_calendar_event159 = 'PREVIOUS_MONTHS'.
      WHEN 'NEXT_MONTHS'.
        mv_month_offset = 1.
        mv_calendar_event159 = 'NEXT_MONTHS'.
      WHEN 'TODAY'.
        mv_month_offset = 0.
        mv_calendar_date159 = '2026-08-30'.
        mv_calendar_event159 = 'TODAY'.
      WHEN 'SET_DATE'.
        IF strlen( lv_requested_date ) = 10
            AND lv_requested_date+4(1) = '-'
            AND lv_requested_date+7(1) = '-'
            AND lv_requested_date >= '2026-08-01'
            AND lv_requested_date <= '2027-12-31'.
          mv_calendar_date159 = lv_requested_date.
          mv_calendar_event159 = 'DATE_SET'.
          write_line( io_session = io_session
                      iv_text    = |Selected { mv_calendar_date159 } within 2026-08-01..2027-12-31| ).
        ELSE.
          mv_calendar_event159 = 'DATE_REJECTED'.
          write_line( io_session = io_session
                      iv_text    = 'Date rejected; use ISO format within 2026-08-01..2027-12-31' ).
        ENDIF.
      WHEN 'READ_DATE'.
        write_line( io_session = io_session
                    iv_text    = |Calendar selection read: { mv_calendar_date159 } ({ COND string( WHEN mv_calendar_range159 = abap_true THEN 'range' ELSE 'single' ) })| ).
        mv_calendar_event159 = 'SELECTION_READ'.
      WHEN 'TOGGLE_RANGE'.
        mv_calendar_range159 = COND abap_bool( WHEN mv_calendar_range159 = abap_true THEN abap_false ELSE abap_true ).
        mv_calendar_event159 = COND string( WHEN mv_calendar_range159 = abap_true THEN 'RANGE_MODE' ELSE 'SINGLE_MODE' ).
        write_line( io_session = io_session
                    iv_text    = |Calendar selection mode: { COND string( WHEN mv_calendar_range159 = abap_true THEN 'range' ELSE 'single' ) }| ).
      WHEN 'MARK_DATE'.
        mv_calendar_marked159 = abap_true.
        mv_calendar_event159 = 'DATE_MARKED'.
        write_line( io_session = io_session
                    iv_text    = |Marked { mv_calendar_date159 }| ).
      WHEN 'CLEAR_DATE'.
        mv_calendar_marked159 = abap_false.
        mv_calendar_event159 = 'MARKS_CLEARED'.
        write_line( io_session = io_session
                    iv_text    = 'Calendar marks cleared' ).
      WHEN 'RECREATE'.
        mv_month_offset = 0.
        mv_calendar_date159 = '2026-08-30'.
        mv_calendar_range159 = abap_false.
        mv_calendar_marked159 = abap_true.
        mv_calendar_generation159 = mv_calendar_generation159 + 1.
        mv_calendar_event159 = 'RECREATED'.
    ENDCASE.
  ENDMETHOD.

  METHOD valid_variant_name.
    rv_valid = xsdbool( iv_name = 'DEFAULT' OR iv_name = 'COMPACT' ).
  ENDMETHOD.

  METHOD build_salv_hierseq.
    TYPES: BEGIN OF ty_header,
             order_id TYPE i,
             customer TYPE string,
           END OF ty_header.
    TYPES: BEGIN OF ty_item,
             order_id TYPE i,
             flight   TYPE string,
             carrier  TYPE string,
             quantity TYPE i,
             price    TYPE p LENGTH 8 DECIMALS 2,
             currency TYPE string,
           END OF ty_item.
    DATA lt_headers TYPE STANDARD TABLE OF ty_header WITH DEFAULT KEY.
    DATA lt_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    DATA lt_binding TYPE salv_t_hierseq_binding.
    DATA lo_hierseq TYPE REF TO cl_salv_hierseq_table.

    lt_headers = VALUE #( ( order_id = 100 customer = 'Order 100' )
                          ( order_id = 200 customer = 'Order 200' ) ).
    lt_items = VALUE #( ( order_id = 100 flight = 'LH400' carrier = 'Lufthansa'
                          quantity = 2 price = '120.00' currency = 'EUR' )
                        ( order_id = 100 flight = 'LH401' carrier = 'Lufthansa'
                          quantity = 1 price = '80.00' currency = 'EUR' )
                        ( order_id = 200 flight = 'UA901' carrier = 'United'
                          quantity = 3 price = '210.00' currency = 'USD' ) ).
    IF mv_ticks > 0.
      SORT lt_items BY price DESCENDING.
    ENDIF.
    lt_binding = VALUE #( ( master = 'ORDER_ID' slave = 'ORDER_ID' ) ).
    TRY.
        cl_salv_hierseq_table=>factory(
          EXPORTING
            t_binding_level1_level2 = lt_binding
          IMPORTING
            r_hierseq               = lo_hierseq
          CHANGING
            t_table_level1          = lt_headers
            t_table_level2          = lt_items ).
        lo_hierseq->get_level( 1 )->set_items_expanded( abap_true ).
        lo_hierseq->display( ).
      CATCH cx_root INTO DATA(lx_error).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Hierarchical sequential SALV fallback'
          table_caption = 'Header and item relations'
          columns       = VALUE #( ( `Level` ) ( `Description` ) ( `Quantity` ) ( `Price` ) )
          rows          = VALUE #(
            ( cell1 = 'Header' cell2 = 'Order 100' cell3 = '-' cell4 = '-' row_header = abap_true )
            ( cell1 = 'Item' cell2 = 'LH400 / Lufthansa' cell3 = '2' cell4 = '120.00 EUR' )
            ( cell1 = 'Item' cell2 = 'LH401 / Lufthansa' cell3 = '1' cell4 = '80.00 EUR' )
            ( cell1 = 'Header' cell2 = 'Order 200' cell3 = '-' cell4 = '-' row_header = abap_true )
            ( cell1 = 'Item' cell2 = 'UA901 / United' cell3 = '3' cell4 = '210.00 USD' ) )
          data_value    = 'Total: 410.00'
          text          = |SALV HIERSEQ fallback: { lx_error->get_text( ) }| ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD handle_variant_command.
    DATA(lv_variant_input) = request_value( io_session = io_session
                                            iv_name    = 'ALV_VARIANT' ).
    DATA(lv_variant_valid) = abap_true.
    IF lv_variant_input IS NOT INITIAL.
      IF valid_variant_name( lv_variant_input ) = abap_true.
        mv_variant = lv_variant_input.
      ELSE.
        lv_variant_valid = abap_false.
        mv_variant_message = 'Variant rejected: only DEFAULT and COMPACT are safe report-local names'.
      ENDIF.
    ENDIF.
    CASE iv_ucomm.
      WHEN 'SAVE_VARIANT'.
        IF lv_variant_valid = abap_true.
          mv_variant_pending = abap_true.
          mv_variant_message = |Confirm save for { mv_variant } (owner { mv_variant_owner }, handle { mv_variant_handle })|.
        ENDIF.
      WHEN 'CONFIRM_VARIANT'.
        IF lv_variant_valid = abap_false.
          mv_variant_message = 'Variant confirmation rejected: unsafe report-local name'.
        ELSEIF mv_variant_pending = abap_true.
          mv_variant_pending = abap_false.
          mv_variant_saved = abap_true.
          mv_variant_layout = 'Carrier, Flight, Seats (saved)'.
          mv_variant_message = |Variant { mv_variant } saved in report-local memory; persistence is not implied|.
        ELSE.
          mv_variant_message = 'No pending variant save requires confirmation'.
        ENDIF.
      WHEN 'APPLY_VARIANT'.
        IF lv_variant_valid = abap_false.
          mv_variant_message = 'Variant apply rejected: unsafe report-local name'.
        ELSEIF mv_variant_saved = abap_true.
          mv_variant_layout = 'Carrier, Flight, Seats (applied)'.
          mv_variant_message = |Variant { mv_variant } applied through handle { mv_variant_handle }|.
        ELSE.
          mv_variant_message = 'Variant apply rejected: save a report-local layout first'.
        ENDIF.
      WHEN 'SWITCH_VARIANT'.
        IF lv_variant_valid = abap_true.
          mv_variant = COND string( WHEN mv_variant = 'DEFAULT' THEN 'COMPACT' ELSE 'DEFAULT' ).
          mv_variant_message = |Switched to safe report-local variant { mv_variant }|.
        ENDIF.
      WHEN 'DELETE_VARIANT'.
        IF lv_variant_valid = abap_true.
          mv_variant_saved = abap_false.
          mv_variant_layout = 'Carrier, Flight, Seats'.
          mv_variant_message = |Variant { mv_variant } deleted from report-local memory|.
        ENDIF.
      WHEN 'CLEANUP_VARIANT'.
        mv_variant_saved = abap_false.
        mv_variant_pending = abap_false.
        mv_variant = 'DEFAULT'.
        mv_variant_layout = 'Carrier, Flight, Seats'.
        mv_variant_message = |Report-local variant handle { mv_variant_handle } cleaned up|.
    ENDCASE.
    build_view( io_session ).
    set_status( io_session ).
    write_line( io_session = io_session
                iv_text    = |ALV variant action { iv_ucomm } completed; { mv_variant_message }| ).
  ENDMETHOD.

  METHOD handle_hierseq_command.
    CASE iv_ucomm.
      WHEN 'SORT_HIERSEQ' OR 'SHOW_TOTALS'.
        mv_ticks = mv_ticks + 1.
      WHEN 'SELECT_HIERSEQ'.
        write_line( io_session = io_session
                    iv_text    = 'Selected item LH400 under header Order 100' ).
    ENDCASE.
    build_view( io_session ).
    set_status( io_session ).
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
        rv_status = COND string(
          WHEN mv_variant_pending = abap_true THEN 'CONFIRM VARIANT'
          WHEN mv_variant_saved = abap_true THEN |VARIANT { mv_variant } SAVED|
          ELSE 'ALV LAYOUT READY' ).
      WHEN '158'.
        rv_status = 'SALV HIERSEQ READY'.
      WHEN '159'.
        rv_status = COND string(
          WHEN mv_calendar_range159 = abap_true THEN |CALENDAR RANGE { mv_calendar_date159 }|
          ELSE |CALENDAR SINGLE { mv_calendar_date159 }| ).
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
          ( 'OPEN_TABLE' ) ( 'OPEN_MESSAGE' ) ( 'OPEN_PROGRESS' ) ( 'POPUP_OK' )
          ( 'POPUP_CANCEL' ) ( 'POPUP_ROW_1' ) ( 'POPUP_ROW_2' ) ( 'POPUP_ROW_3' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'OPEN_CONFIRM' label = 'Confirm popup' icon = 'question' )
          ( ucomm = 'OPEN_INPUT' label = 'Input popup' icon = 'edit' )
          ( ucomm = 'OPEN_SELECTION' label = 'Selection popup' icon = 'select-all' )
          ( ucomm = 'OPEN_TABLE' label = 'Table popup' icon = 'table' )
          ( ucomm = 'OPEN_MESSAGE' label = 'Message popup' icon = 'information' )
          ( ucomm = 'OPEN_PROGRESS' label = 'Progress popup' icon = 'refresh' ) ).
      WHEN '157'.
        ls_status-active_ucomm = VALUE #( ( 'SAVE_VARIANT' ) ( 'APPLY_VARIANT' ) ( 'SWITCH_VARIANT' )
          ( 'DELETE_VARIANT' ) ( 'CLEANUP_VARIANT' ) ( 'CONFIRM_VARIANT' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'SAVE_VARIANT' label = 'Save layout' icon = 'save' )
          ( ucomm = 'APPLY_VARIANT' label = 'Apply layout' icon = 'check' )
          ( ucomm = 'SWITCH_VARIANT' label = 'Switch layout' icon = 'refresh' )
          ( ucomm = 'DELETE_VARIANT' label = 'Delete layout' icon = 'delete' )
          ( ucomm = 'CLEANUP_VARIANT' label = 'Cleanup layouts' icon = 'delete' )
          ( ucomm = 'CONFIRM_VARIANT' label = 'Confirm save' icon = 'check' ) ).
      WHEN '158'.
        ls_status-active_ucomm = VALUE #( ( 'SORT_HIERSEQ' ) ( 'SELECT_HIERSEQ' ) ( 'SHOW_TOTALS' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'SORT_HIERSEQ' label = 'Sort hierarchy' icon = 'sort' )
          ( ucomm = 'SELECT_HIERSEQ' label = 'Select item' icon = 'select-all' )
          ( ucomm = 'SHOW_TOTALS' label = 'Show totals' icon = 'sum' ) ).
      WHEN '159'.
        ls_status-active_ucomm = VALUE #( ( 'PREVIOUS_MONTHS' ) ( 'NEXT_MONTHS' )
          ( 'TODAY' ) ( 'SET_DATE' ) ( 'READ_DATE' ) ( 'TOGGLE_RANGE' )
          ( 'MARK_DATE' ) ( 'CLEAR_DATE' ) ( 'RECREATE' ) ).
        ls_status-icon_bar = VALUE #(
          ( ucomm = 'PREVIOUS_MONTHS' label = 'Previous months' icon = 'arrow-left' )
          ( ucomm = 'NEXT_MONTHS' label = 'Next months' icon = 'arrow-right' )
          ( ucomm = 'TODAY' label = 'Today' icon = 'calendar' )
          ( ucomm = 'SET_DATE' label = 'Set date' icon = 'check' )
          ( ucomm = 'READ_DATE' label = 'Read selection' icon = 'display' )
          ( ucomm = 'TOGGLE_RANGE' label = 'Toggle range' icon = 'select-all' )
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
    DATA lt_popup_log_rows TYPE zcl_gg_host_surface=>ty_surface_rows.
    DATA lt_calendar_rows TYPE zcl_gg_host_surface=>ty_surface_rows.
    DATA lt_fcat TYPE lvc_t_fcat.

    CASE mv_mode.
      WHEN '152'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT152' ).
        IF mo_timer IS NOT BOUND.
          mo_timer = NEW cl_gui_timer( ).
          mv_timer_instance = mv_timer_instance + 1.
        ENDIF.
        mo_timer->interval = mv_interval.
        cl_gui_control=>initialize( control = mo_timer
                                    parent  = lo_root
                                    kind    = 'TIMER' ).
        lo_root->add_child( mo_timer ).
        IF mv_running = abap_true.
          mo_timer->run( ).
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
          kind           = zcl_gg_host_surface=>surface_document
          aria_label     = 'Browser frontend capability report'
          title          = 'Explicit browser capabilities'
          text           = 'Desktop-only operations are refused or require a real browser permission. The host never claims a file, clipboard, directory, registry, or URL operation happened without evidence.'
          input_label    = 'Upload fixture'
          input_name     = 'UPLOAD_FILE'
          input_type     = 'file'
          download_href  = '/assets/fixtures/frontend-services.txt'
          download_label = 'Download browser fixture'
          actions        = VALUE #(
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
                          ( cell1 = 'Size' cell2 = |{ mv_dialog_width } x { mv_dialog_height }| )
                          ( cell1 = 'Focus' cell2 = COND string( WHEN mv_dialog_focus = abap_true THEN 'dialog' ELSE 'parent' ) )
                          ( cell1 = 'Last event' cell2 = mv_dialog_event ) )
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'MOVE_DIALOG' label = 'Move' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RESIZE_DIALOG' label = 'Resize' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'FOCUS_DIALOG' label = 'Focus dialog' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PARENT_ACTION' label = 'Parent action' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CLOSE_DIALOG' label = 'Close' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '156'.
        LOOP AT mt_popup_log INTO DATA(lv_popup_log_entry).
          APPEND VALUE #( cell1 = |{ sy-tabix }| cell2 = lv_popup_log_entry ) TO lt_popup_log_rows.
        ENDLOOP.
        ls_surface = VALUE #(
          kind          = zcl_gg_host_surface=>surface_document
          aria_label    = 'Popup compatibility gallery'
          title         = 'Typed popup compatibility gallery'
          text          = COND string( WHEN mv_popup_result IS INITIAL THEN 'Open a popup family and close it to record its typed return.' ELSE mv_popup_result )
          table_caption = 'Ordered popup event log'
          columns       = VALUE #( ( `#` ) ( `Popup event` ) )
          rows          = lt_popup_log_rows
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_CONFIRM' label = 'Confirm' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_INPUT' label = 'Input' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_SELECTION' label = 'Selection' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_TABLE' label = 'Table' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_MESSAGE' label = 'Message' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'OPEN_PROGRESS' label = 'Progress' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
        IF mv_popup_kind IS NOT INITIAL.
          DATA(lv_popup_text) = COND string(
            WHEN mv_popup_kind = 'CONFIRM' THEN 'Confirm this server-owned action.'
            WHEN mv_popup_kind = 'INPUT' THEN 'Enter a value; the result is returned as text.'
            WHEN mv_popup_kind = 'SELECTION' THEN 'Select one of the available values.'
            WHEN mv_popup_kind = 'TABLE' THEN 'Choose a row; the server returns the typed row number.'
            WHEN mv_popup_kind = 'MESSAGE' THEN 'This is an informational message.'
            ELSE 'Progress is reported without blocking the browser.' ).
          zcl_gg_host_surface=>set_surface( VALUE #(
            kind        = zcl_gg_host_surface=>surface_popup
            aria_label  = |{ mv_popup_kind } popup|
            title       = |{ mv_popup_kind } popup|
            text        = lv_popup_text
            input_label = COND string( WHEN mv_popup_kind = 'INPUT' THEN 'Value' ELSE '' )
            input_name  = COND string( WHEN mv_popup_kind = 'INPUT' THEN 'POPUP_VALUE' ELSE '' )
            rows        = COND #( WHEN mv_popup_kind = 'TABLE' THEN VALUE #(
                            ( cell1 = 'Carrier LH400' cell2 = '180 seats' )
                            ( cell1 = 'Carrier UA901' cell2 = '210 seats' )
                            ( cell1 = 'Carrier AF010' cell2 = '160 seats' ) ) ELSE VALUE #( ) )
            actions     = COND #( WHEN mv_popup_kind = 'TABLE' THEN VALUE #(
                            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_ROW_1' label = 'Select row 1' )
                            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_ROW_2' label = 'Select row 2' )
                            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_ROW_3' label = 'Select row 3' )
                            ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_CANCEL' label = 'Cancel' ) )
                        ELSE VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_OK' label = 'OK' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'POPUP_CANCEL' label = 'Cancel' ) ) ) ) ).
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
          text          = |Layout: { mv_variant_layout }; owner={ mv_variant_owner }, handle={ mv_variant_handle }, { mv_variant_message }. No database persistence is implied.| ).
        ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SAVE_VARIANT' label = 'Save' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'APPLY_VARIANT' label = 'Apply' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SWITCH_VARIANT' label = 'Switch' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DELETE_VARIANT' label = 'Delete' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CLEANUP_VARIANT' label = 'Cleanup' )
                                      ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'CONFIRM_VARIANT'
                                        label = 'Confirm save'
                                        disabled = xsdbool( mv_variant_pending = abap_false ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '158'.
        build_salv_hierseq( ).
      WHEN '159'.
        DATA(lv_first_month) = COND string( WHEN mv_month_offset = 0 THEN '2026-08' ELSE '2026-11' ).
        DATA(lv_focus_date) = COND string( WHEN mv_month_offset = 0 THEN mv_calendar_date159 ELSE '2026-11-13' ).
        IF mv_month_offset = 0.
          lt_calendar_rows = VALUE #(
            ( cell1 = '2026-08' cell2 = '31-35' cell3 = lv_focus_date cell4 = COND string( WHEN mv_calendar_marked159 = abap_true THEN 'marked' ELSE 'clear' ) )
            ( cell1 = '2026-09' cell2 = '36-39' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2026-10' cell2 = '40-44' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2026-11' cell2 = '45-48' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2026-12' cell2 = '49-53' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-01' cell2 = '01-04' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-02' cell2 = '05-08' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-03' cell2 = '09-13' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-04' cell2 = '14-17' cell3 = '' cell4 = 'clear' ) ).
        ELSE.
          lt_calendar_rows = VALUE #(
            ( cell1 = '2026-11' cell2 = '45-48' cell3 = lv_focus_date cell4 = COND string( WHEN mv_calendar_marked159 = abap_true THEN 'marked' ELSE 'clear' ) )
            ( cell1 = '2026-12' cell2 = '49-53' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-01' cell2 = '01-04' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-02' cell2 = '05-08' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-03' cell2 = '09-13' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-04' cell2 = '14-17' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-05' cell2 = '18-22' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-06' cell2 = '23-26' cell3 = '' cell4 = 'clear' )
            ( cell1 = '2027-07' cell2 = '27-30' cell3 = '' cell4 = 'clear' ) ).
        ENDIF.
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Nine month calendar'
          table_caption = |Nine-month calendar from { lv_first_month }|
          columns       = VALUE #( ( `Month` ) ( `ISO weeks` ) ( `Focus / selection` ) ( `Marks` ) )
          rows          = lt_calendar_rows
          input_label   = 'Focus date'
          input_name    = 'CALENDAR_DATE'
          input_type    = 'date'
          input_value   = mv_calendar_date159
          data_value    = |generation={ mv_calendar_generation159 }; mode={ COND string( WHEN mv_calendar_range159 = abap_true THEN 'range' ELSE 'single' ) }; selection={ mv_calendar_date159 }; bounds=2026-08-01..2027-12-31; locale=en|
          text          = |Week numbers, nine-month view, and selection are deterministic and locale-stable. Last event: { mv_calendar_event159 }.|
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PREVIOUS_MONTHS' label = 'Previous' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'NEXT_MONTHS' label = 'Next' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'TODAY' label = 'Today' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SET_DATE' label = 'Set date' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'READ_DATE' label = 'Read selection' )
                             ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'TOGGLE_RANGE' label = 'Toggle range' )
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
            IF mo_timer IS BOUND.
              mo_timer->cancel( ).
            ENDIF.
          WHEN 'TICK_TIMER'.
            IF mo_timer IS BOUND.
              mo_timer->tick( ).
              mv_ticks = mo_timer->get_tick_count( ).
            ENDIF.
          WHEN 'FASTER'.
            mv_interval = COND #( WHEN mv_interval > 100 THEN mv_interval - 100 ELSE 100 ).
          WHEN 'SLOWER'.
            mv_interval = mv_interval + 100.
          WHEN 'REUSE_TIMER'.
            IF mo_timer IS BOUND.
              mo_timer->cancel( ).
            ENDIF.
            mo_timer = NEW cl_gui_timer( ).
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
            mv_dialog_event = 'MOVED'.
          WHEN 'RESIZE_DIALOG'.
            mv_dialog_width = mv_dialog_width + 20.
            mv_dialog_height = mv_dialog_height + 10.
            mv_dialog_event = 'RESIZED'.
          WHEN 'FOCUS_DIALOG'.
            mv_dialog_focus = abap_true.
            mv_dialog_event = 'FOCUSED'.
            write_line( io_session = io_session
                        iv_text    = 'Modeless dialog focus restored without blocking the parent' ).
          WHEN 'PARENT_ACTION'.
            mv_dialog_focus = abap_false.
            mv_dialog_event = 'PARENT_INTERACTION'.
            write_line( io_session = io_session
                        iv_text    = 'Parent action remained available while dialog was modeless' ).
          WHEN 'CLOSE_DIALOG'.
            mv_dialog_open = abap_false.
            mv_dialog_focus = abap_false.
            mv_dialog_event = 'CLOSED'.
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
          WHEN 'OPEN_TABLE'.
            mv_popup_kind = 'TABLE'.
          WHEN 'OPEN_MESSAGE'.
            mv_popup_kind = 'MESSAGE'.
          WHEN 'OPEN_PROGRESS'.
            mv_popup_kind = 'PROGRESS'.
          WHEN 'POPUP_OK'.
            mv_popup_result = |{ mv_popup_kind } returned typed OK|.
            APPEND |{ mv_popup_kind } -> OK| TO mt_popup_log.
            CLEAR mv_popup_kind.
          WHEN 'POPUP_ROW_1' OR 'POPUP_ROW_2' OR 'POPUP_ROW_3'.
            DATA(lv_popup_row) = iv_ucomm.
            SHIFT lv_popup_row LEFT BY 10 PLACES.
            mv_popup_result = |{ mv_popup_kind } returned typed row { lv_popup_row }|.
            APPEND |{ mv_popup_kind } -> row { lv_popup_row }| TO mt_popup_log.
            CLEAR mv_popup_kind.
          WHEN 'POPUP_CANCEL'.
            mv_popup_result = |{ mv_popup_kind } cancelled with return code 1|.
            APPEND |{ mv_popup_kind } -> CANCEL| TO mt_popup_log.
            CLEAR mv_popup_kind.
        ENDCASE.
        build_view( io_session ).
        set_status( io_session ).
      WHEN '157'.
        handle_variant_command( io_session = io_session
                                iv_ucomm   = iv_ucomm ).
      WHEN '158'.
        handle_hierseq_command( io_session = io_session
                                iv_ucomm   = iv_ucomm ).
      WHEN '159'.
        handle_calendar_command( io_session = io_session
                                 iv_ucomm   = iv_ucomm ).
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

  METHOD stop_session_resources.
    IF mo_timer IS BOUND.
      mo_timer->cancel( ).
      CLEAR mo_timer.
      CLEAR mv_ticks.
      mv_running = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_session_lifecycle_v1~on_close.
    stop_session_resources( ).
    clear_view( ).
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
