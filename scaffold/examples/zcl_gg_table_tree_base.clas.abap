CLASS zcl_gg_table_tree_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared report implementation for the structured table and tree examples
* 135-147. The examples use the public control APIs and keep application
* actions in the server-side list callback.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             carrier TYPE string,
             flight  TYPE string,
             seats   TYPE i,
             active  TYPE string,
             inspect TYPE string,
           END OF ty_row.
    TYPES ty_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.

    DATA mv_mode TYPE string.
    DATA mv_action_count TYPE i.
    DATA mv_sorted TYPE abap_bool.
    DATA mv_filtered TYPE abap_bool.
    DATA mv_chart_color TYPE string.
    DATA mv_tree_expanded140 TYPE abap_bool.
    DATA mv_tree_selected140 TYPE string.
    DATA mv_tree_lazy140 TYPE abap_bool.
    DATA mv_tree_menu140 TYPE abap_bool.
    DATA mv_tree_compare140 TYPE abap_bool.
    DATA mv_tree_status_visible141 TYPE abap_bool.
    DATA mv_tree_expanded143 TYPE abap_bool.
    DATA mv_tree_lazy143 TYPE abap_bool.
    DATA mv_tree_added143 TYPE abap_bool.
    DATA mv_tree_selected143 TYPE string.
    DATA mv_tree_event143 TYPE string.
    DATA mv_salv_tree_expanded147 TYPE abap_bool.
    DATA mv_salv_tree_lazy147 TYPE abap_bool.
    DATA mv_salv_tree_added147 TYPE abap_bool.
    DATA mv_salv_tree_selected147 TYPE string.
    DATA mv_salv_tree_event147 TYPE string.
    DATA mv_dynamic_generation TYPE i.
    DATA mv_dynamic_style TYPE abap_bool.
    DATA mv_edit_seats TYPE i.
    DATA mv_edit_saved_seats TYPE i.
    DATA mv_edit_row_count TYPE i.
    DATA mv_edit_status TYPE string.
    DATA mv_event_last TYPE string.

    METHODS build_view
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.

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

    METHODS table_surface
      IMPORTING
        iv_label          TYPE string
      RETURNING
        VALUE(rs_surface) TYPE zcl_gg_host_surface=>ty_surface.

    METHODS handle_tree_command
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_ucomm   TYPE zif_gg_list_processing_types_v1=>ty_ucomm.

    METHODS handle_alv_command
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_ucomm   TYPE zif_gg_list_processing_types_v1=>ty_ucomm.

    METHODS refresh_report
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.

    METHODS build_salv_tree
      IMPORTING
        it_rows TYPE ty_rows.

    CLASS-METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_table_tree_base IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
    mv_chart_color = '#2668A3'.
    mv_tree_expanded140 = abap_true.
    mv_tree_selected140 = 'NODE-LH400'.
    mv_tree_status_visible141 = abap_true.
    mv_tree_expanded143 = abap_true.
    mv_tree_lazy143 = abap_false.
    mv_tree_selected143 = 'TREE-2'.
    mv_tree_event143 = 'No ALV tree event dispatched yet'.
    mv_salv_tree_expanded147 = abap_true.
    mv_salv_tree_selected147 = 'NODE-2'.
    mv_salv_tree_event147 = 'No SALV tree event dispatched yet'.
    mv_dynamic_generation = 1.
    mv_edit_seats = 180.
    mv_edit_saved_seats = 180.
    mv_edit_row_count = 3.
    mv_edit_status = 'Draft unchanged; no database persistence'.
    mv_event_last = 'No ALV event dispatched yet'.
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

  METHOD unicode_text.
    DATA(lv_utf8) = CONV xstring( iv_hex ).
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input    = lv_utf8
                                                     encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = rv_text ).
  ENDMETHOD.

  METHOD set_status.
    CASE mv_mode.
      WHEN '135'.
        io_session->get_list( )->set_status( VALUE #(
          status       = COND string( WHEN mv_dynamic_style = abap_true THEN 'ALV DYNAMIC STYLE' ELSE 'ALV DYNAMIC' )
          active_ucomm = VALUE #( ( 'DYNAMIC_APPEND' ) ( 'DYNAMIC_STYLE' ) ( 'DYNAMIC_INSPECT' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'DYNAMIC_APPEND' label = 'Append runtime row' icon = 'add' )
            ( ucomm = 'DYNAMIC_STYLE' label = 'Toggle generated style' icon = 'palette' )
            ( ucomm = 'DYNAMIC_INSPECT' label = 'Inspect structure' icon = 'display' ) ) ) ).
      WHEN '136'.
        io_session->get_list( )->set_status( VALUE #(
          status       = COND string( WHEN mv_edit_status CS 'rejected' THEN 'EDIT VALIDATION ERROR' ELSE 'EDITABLE ALV' )
          active_ucomm = VALUE #( ( 'SAVE_GRID' ) ( 'DISCARD_GRID' ) ( 'APPEND_ROW' ) ( 'COPY_ROW' )
                                  ( 'DELETE_ROW' ) ( 'VALIDATE_GRID' ) ( 'ALV_F4' ) ( 'ALV_HOTSPOT' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'SAVE_GRID' label = 'Save draft' icon = 'save' )
            ( ucomm = 'DISCARD_GRID' label = 'Discard draft' icon = 'undo' )
            ( ucomm = 'APPEND_ROW' label = 'Append row' icon = 'add' )
            ( ucomm = 'COPY_ROW' label = 'Copy row' icon = 'copy' )
            ( ucomm = 'DELETE_ROW' label = 'Delete row' icon = 'delete' )
            ( ucomm = 'VALIDATE_GRID' label = 'Validate changes' icon = 'check' )
            ( ucomm = 'ALV_F4' label = 'Carrier F4' icon = 'search' )
            ( ucomm = 'ALV_HOTSPOT' label = 'Inspect hotspot' icon = 'link' ) ) ) ).
      WHEN '137'.
        io_session->get_list( )->set_status( VALUE #(
          status       = COND #( WHEN mv_filtered = abap_true THEN 'FILTERED'
                           WHEN mv_sorted = abap_true THEN 'SORTED'
                           ELSE 'ALV CRITERIA' )
          active_ucomm = VALUE #( ( 'APPLY_CRITERIA' ) )
          icon_bar     = VALUE #( ( ucomm = 'APPLY_CRITERIA' label = 'Apply criteria' icon = 'filter' ) ) ) ).
      WHEN '138'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'ALV SELECTION'
          active_ucomm = VALUE #( ( 'SELECT_ROW' ) )
          icon_bar     = VALUE #( ( ucomm = 'SELECT_ROW' label = 'Select row' icon = 'select-all' ) ) ) ).
      WHEN '139'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'ALV EVENTS'
          active_ucomm = VALUE #( ( 'ALV_EVENT' ) ( 'ALV_TOOLBAR' ) ( 'ALV_MENU' ) ( 'ALV_DELAYED' )
                                  ( 'ALV_PRINT' ) ( 'ALV_DATA_CHANGE' ) ( 'ALV_DROP' ) ( 'ALV_APP_EVENT' )
                                  ( 'ALV_HOTSPOT' ) ( 'ALV_DOUBLE_CLICK' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'ALV_EVENT' label = 'Run event' icon = 'event' )
            ( ucomm = 'ALV_TOOLBAR' label = 'Toolbar event' icon = 'toolbar' )
            ( ucomm = 'ALV_MENU' label = 'Menu event' icon = 'menu' )
            ( ucomm = 'ALV_DELAYED' label = 'Delayed selection' icon = 'clock' )
            ( ucomm = 'ALV_PRINT' label = 'Print event' icon = 'print' )
            ( ucomm = 'ALV_DATA_CHANGE' label = 'Data changed' icon = 'edit' )
            ( ucomm = 'ALV_DROP' label = 'Drag/drop event' icon = 'move' )
            ( ucomm = 'ALV_APP_EVENT' label = 'Application event' icon = 'event' )
            ( ucomm = 'ALV_HOTSPOT' label = 'Hotspot event' icon = 'link' )
            ( ucomm = 'ALV_DOUBLE_CLICK' label = 'Double-click event' icon = 'select' ) ) ) ).
      WHEN '140'.
        io_session->get_list( )->set_status( VALUE #(
          status       = COND string( WHEN mv_tree_compare140 = abap_true THEN 'TREE COMPARE' ELSE 'SIMPLE TREE' )
          active_ucomm = VALUE #( ( 'EXPAND_TREE' ) ( 'COLLAPSE_TREE' ) ( 'SELECT_TREE' )
                                  ( 'LAZY_LOAD' ) ( 'TREE_CONTEXT' ) ( 'COMPARE_MODE' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'EXPAND_TREE' label = 'Expand tree' icon = 'expand' )
            ( ucomm = 'COLLAPSE_TREE' label = 'Collapse tree' icon = 'collapse' )
            ( ucomm = 'SELECT_TREE' label = 'Select node' icon = 'select-all' )
            ( ucomm = 'LAZY_LOAD' label = 'Load children' icon = 'refresh' )
            ( ucomm = 'TREE_CONTEXT' label = 'Context menu' icon = 'menu' )
            ( ucomm = 'COMPARE_MODE' label = 'Compare models' icon = 'compare' ) ) ) ).
      WHEN '141'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'COLUMN TREE ITEMS'
          active_ucomm = VALUE #( ( 'TOGGLE_STATUS_COLUMN' ) ( 'COLUMN_EXPAND' ) ( 'COLUMN_SELECT' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'TOGGLE_STATUS_COLUMN' label = 'Toggle status column' icon = 'display' )
            ( ucomm = 'COLUMN_EXPAND' label = 'Expand hierarchy' icon = 'expand' )
            ( ucomm = 'COLUMN_SELECT' label = 'Select item' icon = 'select-all' ) ) ) ).
      WHEN '142'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'TREE EVENTS'
          active_ucomm = VALUE #( ( 'TREE_SELECT' ) )
          icon_bar     = VALUE #( ( ucomm = 'TREE_SELECT' label = 'Select node' icon = 'select-all' ) ) ) ).
      WHEN '143'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'ALV TREE'
          active_ucomm = VALUE #( ( 'EXPAND_ALV_TREE' ) ( 'COLLAPSE_ALV_TREE' ) ( 'SELECT_ALV_TREE' )
                                  ( 'LAZY_ALV_TREE' ) ( 'ADD_ALV_TREE' ) ( 'CALCULATE_ALV_TREE' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'EXPAND_ALV_TREE' label = 'Expand tree' icon = 'expand' )
            ( ucomm = 'COLLAPSE_ALV_TREE' label = 'Collapse tree' icon = 'collapse' )
            ( ucomm = 'SELECT_ALV_TREE' label = 'Select node' icon = 'select-all' )
            ( ucomm = 'LAZY_ALV_TREE' label = 'Load lazy children' icon = 'refresh' )
            ( ucomm = 'ADD_ALV_TREE' label = 'Add leaf' icon = 'add' )
            ( ucomm = 'CALCULATE_ALV_TREE' label = 'Calculate totals' icon = 'sum' ) ) ) ).
      WHEN '145'.
        io_session->get_list( )->set_status( VALUE #(
          status       = COND #( WHEN mv_filtered = abap_true THEN 'SALV FILTERED' ELSE 'SALV TOTALS' )
          active_ucomm = VALUE #( ( 'SALV_FILTER' ) )
          icon_bar     = VALUE #( ( ucomm = 'SALV_FILTER' label = 'Filter SALV' icon = 'filter' ) ) ) ).
      WHEN '147'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'SALV EVENTS'
          active_ucomm = VALUE #( ( 'SALV_LINK' ) ( 'SALV_DOUBLE' ) ( 'SALV_EXPAND' ) ( 'SALV_COLLAPSE' ) ( 'SALV_ADD_LEAF' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'SALV_LINK' label = 'Open row' icon = 'link' )
            ( ucomm = 'SALV_DOUBLE' label = 'Double-click row' icon = 'select' )
            ( ucomm = 'SALV_EXPAND' label = 'Expand tree' icon = 'expand' )
            ( ucomm = 'SALV_COLLAPSE' label = 'Collapse tree' icon = 'collapse' )
            ( ucomm = 'SALV_ADD_LEAF' label = 'Add leaf' icon = 'add' ) ) ) ).
      WHEN '148'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'GRAPHICS FALLBACK'
          active_ucomm = VALUE #( ( 'SET_CHART_COLOR' ) )
          icon_bar     = VALUE #( ( ucomm = 'SET_CHART_COLOR' label = 'Set chart color' icon = 'palette' ) ) ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD table_surface.
    rs_surface = VALUE #(
      kind          = zcl_gg_host_surface=>surface_table
      aria_label    = iv_label
      table_caption = iv_label
      columns       = VALUE #( ( `Carrier` ) ( `Flight` ) ( `Seats` ) )
      rows          = VALUE #(
        ( cell1 = 'Lufthansa' cell2 = 'LH400' cell3 = '180' )
        ( cell1 = 'United' cell2 = 'UA901' cell3 = '210' )
        ( cell1 = 'Air France' cell2 = 'AF010' cell3 = '160' ) ) ).
  ENDMETHOD.

  METHOD handle_tree_command.
    CASE mv_mode.
      WHEN '140'.
        CASE iv_ucomm.
          WHEN 'EXPAND_TREE'.
            mv_tree_expanded140 = abap_true.
          WHEN 'COLLAPSE_TREE'.
            mv_tree_expanded140 = abap_false.
          WHEN 'SELECT_TREE'.
            mv_tree_selected140 = 'NODE-LH400'.
          WHEN 'LAZY_LOAD'.
            mv_tree_lazy140 = abap_true.
          WHEN 'TREE_CONTEXT'.
            mv_tree_menu140 = abap_true.
          WHEN 'COMPARE_MODE'.
            mv_tree_compare140 = COND abap_bool(
              WHEN mv_tree_compare140 = abap_true THEN abap_false ELSE abap_true ).
        ENDCASE.
      WHEN '141'.
        CASE iv_ucomm.
          WHEN 'TOGGLE_STATUS_COLUMN'.
            mv_tree_status_visible141 = COND abap_bool(
              WHEN mv_tree_status_visible141 = abap_true THEN abap_false ELSE abap_true ).
          WHEN 'COLUMN_EXPAND'.
            write_line( io_session = io_session
                        iv_text    = 'Column tree hierarchy expanded; lazy items retained by opaque keys' ).
          WHEN 'COLUMN_SELECT'.
            write_line( io_session = io_session
                        iv_text    = 'Selected column item COLUMN-LINK' ).
        ENDCASE.
      WHEN '143'.
        CASE iv_ucomm.
          WHEN 'EXPAND_ALV_TREE'.
            mv_tree_expanded143 = abap_true.
            mv_tree_event143 = 'ALV tree expanded'.
          WHEN 'COLLAPSE_ALV_TREE'.
            mv_tree_expanded143 = abap_false.
            mv_tree_event143 = 'ALV tree collapsed'.
          WHEN 'SELECT_ALV_TREE'.
            mv_tree_selected143 = 'TREE-2'.
            mv_tree_event143 = 'ALV tree node TREE-2 selected'.
          WHEN 'LAZY_ALV_TREE'.
            mv_tree_lazy143 = abap_true.
            mv_tree_event143 = 'ALV tree lazy children loaded'.
          WHEN 'ADD_ALV_TREE'.
            mv_tree_added143 = abap_true.
            mv_tree_event143 = 'ALV tree leaf added under TREE-1'.
          WHEN 'CALCULATE_ALV_TREE'.
            mv_tree_event143 = 'ALV tree calculation completed; typed seats total is 550'.
        ENDCASE.
      WHEN '147'.
        CASE iv_ucomm.
          WHEN 'SALV_LINK'.
            mv_salv_tree_selected147 = 'NODE-2'.
            mv_salv_tree_event147 = 'SALV link event delivered for NODE-2 / FLIGHT'.
          WHEN 'SALV_DOUBLE'.
            mv_salv_tree_selected147 = 'NODE-2'.
            mv_salv_tree_event147 = 'SALV double-click event delivered for NODE-2 / FLIGHT'.
          WHEN 'SALV_EXPAND'.
            mv_salv_tree_expanded147 = abap_true.
            mv_salv_tree_event147 = 'SALV tree expanded; child nodes visible'.
          WHEN 'SALV_COLLAPSE'.
            mv_salv_tree_expanded147 = abap_false.
            mv_salv_tree_event147 = 'SALV tree collapsed; child nodes remain in server state'.
          WHEN 'SALV_ADD_LEAF'.
            mv_salv_tree_added147 = abap_true.
            mv_salv_tree_event147 = 'SALV add-leaf mutation completed under NODE-1'.
        ENDCASE.
    ENDCASE.
  ENDMETHOD.

  METHOD refresh_report.
    cl_gui_control=>clear( ).
    zcl_gg_host_surface=>clear( ).
    build_view( io_session ).
    set_status( io_session ).
  ENDMETHOD.

  METHOD handle_alv_command.
    CASE mv_mode.
      WHEN '135'.
        CASE iv_ucomm.
          WHEN 'DYNAMIC_APPEND'.
            mv_dynamic_generation = mv_dynamic_generation + 1.
            write_line( io_session = io_session
                        iv_text    = |Dynamic row appended; generation { mv_dynamic_generation }| ).
          WHEN 'DYNAMIC_STYLE'.
            mv_dynamic_style = COND abap_bool(
              WHEN mv_dynamic_style = abap_true THEN abap_false ELSE abap_true ).
            write_line( io_session = io_session
                        iv_text    = |Generated STYLE component { COND string( WHEN mv_dynamic_style = abap_true THEN 'enabled' ELSE 'disabled' ) }| ).
          WHEN 'DYNAMIC_INSPECT'.
            write_line( io_session = io_session
                        iv_text    = 'Dynamic structure ZGG_DYNAMIC_FLIGHT_ROW has CARRIER, FLIGHT, and SEATS fields; totals remain typed' ).
        ENDCASE.
        refresh_report( io_session ).
      WHEN '136'.
        DATA(lv_seats_value) = request_value( io_session = io_session
                                              iv_name    = 'ALV-SEATS' ).
        IF lv_seats_value IS NOT INITIAL AND iv_ucomm <> 'DISCARD_GRID'.
          TRY.
              mv_edit_seats = CONV i( lv_seats_value ).
            CATCH cx_root.
              CLEAR mv_edit_seats.
          ENDTRY.
        ENDIF.
        CASE iv_ucomm.
          WHEN 'SAVE_GRID'.
            TRY.
                DATA(lv_seats) = CONV i( lv_seats_value ).
                IF lv_seats BETWEEN 1 AND 999.
                  mv_edit_seats = lv_seats.
                  mv_edit_saved_seats = lv_seats.
                  mv_edit_status = |Draft saved in memory ({ lv_seats } seats); database unchanged|.
                ELSE.
                  mv_edit_status = 'Draft rejected: seats must be between 1 and 999'.
                ENDIF.
              CATCH cx_root.
                mv_edit_status = 'Draft rejected: seats must be a number'.
            ENDTRY.
            mv_action_count = mv_action_count + 1.
            write_line( io_session = io_session
                        iv_text    = |ALV changed data accepted in memory ({ mv_action_count }); no database persistence| ).
          WHEN 'DISCARD_GRID'.
            mv_edit_seats = mv_edit_saved_seats.
            mv_edit_status = 'Draft discarded; saved in-memory value restored'.
            write_line( io_session = io_session
                        iv_text    = 'ALV draft discarded without database access' ).
          WHEN 'APPEND_ROW'.
            mv_edit_row_count = mv_edit_row_count + 1.
            mv_edit_status = |Row appended in memory; { mv_edit_row_count } rows|.
            write_line( io_session = io_session
                        iv_text    = 'ALV row appended in memory' ).
          WHEN 'COPY_ROW'.
            mv_edit_row_count = mv_edit_row_count + 1.
            mv_edit_status = |Row copied in memory; { mv_edit_row_count } rows|.
            write_line( io_session = io_session
                        iv_text    = 'ALV row copied in memory' ).
          WHEN 'DELETE_ROW'.
            IF mv_edit_row_count > 1.
              mv_edit_row_count = mv_edit_row_count - 1.
            ENDIF.
            mv_edit_status = |Row deleted in memory; { mv_edit_row_count } rows|.
            write_line( io_session = io_session
                        iv_text    = 'ALV row deleted in memory' ).
          WHEN 'VALIDATE_GRID'.
            IF mv_edit_seats BETWEEN 1 AND 999.
              mv_edit_status = 'Validation passed: changed data is internally consistent'.
              write_line( io_session = io_session
                          iv_text    = 'ALV changed-data protocol validation passed' ).
            ELSE.
              mv_edit_status = 'Draft rejected: validation requires seats between 1 and 999'.
              write_line( io_session = io_session
                          iv_text    = 'ALV changed-data protocol rejected the draft' ).
            ENDIF.
          WHEN 'ALV_F4'.
            write_line( io_session = io_session
                        iv_text    = 'ALV F4 event delivered for CARRIER; value help remains report-owned' ).
          WHEN 'ALV_HOTSPOT'.
            write_line( io_session = io_session
                        iv_text    = 'ALV hotspot/button event delivered for INSPECT' ).
        ENDCASE.
        refresh_report( io_session ).
      WHEN '139'.
        CASE iv_ucomm.
          WHEN 'ALV_EVENT'.
            mv_event_last = 'Event log: application toolbar event delivered'.
          WHEN 'ALV_TOOLBAR'.
            mv_event_last = 'Event log: custom toolbar event delivered'.
          WHEN 'ALV_MENU'.
            mv_event_last = 'Event log: custom menu event delivered'.
          WHEN 'ALV_DELAYED'.
            mv_event_last = 'Event log: delayed selection callback delivered'.
          WHEN 'ALV_PRINT'.
            mv_event_last = 'Event log: print event delivered'.
          WHEN 'ALV_DATA_CHANGE'.
            mv_event_last = 'Event log: data_changed and data_changed_finished delivered'.
          WHEN 'ALV_DROP'.
            mv_event_last = 'Event log: drag/drop event delivered'.
          WHEN 'ALV_APP_EVENT'.
            mv_event_last = 'Event log: application event mode delivered'.
          WHEN 'ALV_HOTSPOT'.
            mv_event_last = 'Event log: hotspot click delivered for FLIGHT'.
          WHEN 'ALV_DOUBLE_CLICK'.
            mv_event_last = 'Event log: double-click delivered for row 2'.
        ENDCASE.
        write_line( io_session = io_session
                    iv_text    = mv_event_last ).
        refresh_report( io_session ).
    ENDCASE.
  ENDMETHOD.

  METHOD build_salv_tree.
    DATA lt_rows TYPE ty_rows.
    DATA lo_salv_tree TYPE REF TO cl_salv_tree.
    DATA lo_salv_root TYPE REF TO cl_salv_node.
    DATA lo_salv_leaf TYPE REF TO cl_salv_node.
    DATA ls_tree_row TYPE ty_row.
    DATA ls_surface TYPE zcl_gg_host_surface=>ty_surface.

    lt_rows = it_rows.
    TRY.
        cl_salv_tree=>factory(
          IMPORTING
            r_salv_tree = lo_salv_tree
          CHANGING
            t_table     = lt_rows ).
        lo_salv_tree->get_tree_settings( )->set_header( 'SALV flight tree' ).
        lo_salv_tree->get_tree_settings( )->set_hierarchy_header( 'Flight hierarchy' ).
        lo_salv_root = lo_salv_tree->get_nodes( )->add_node(
          text     = 'Flights'
          folder   = abap_true
          expander = abap_true ).
        READ TABLE lt_rows INTO ls_tree_row INDEX 1.
        lo_salv_leaf = lo_salv_tree->get_nodes( )->add_node(
          related_node = lo_salv_root->get_key( )
          data_row     = ls_tree_row
          text         = |LH400 { unicode_text( `E28094` ) } Lufthansa| ).
        lo_salv_root->get_item( 'ACTIVE' )->set_type( if_salv_c_cell_type=>checkbox ).
        lo_salv_root->get_item( 'ACTIVE' )->set_checked( abap_true ).
        lo_salv_leaf->get_item( 'FLIGHT' )->set_type( if_salv_c_cell_type=>link ).
        lo_salv_leaf->get_item( 'FLIGHT' )->set_value( 'Open LH400' ).
        lo_salv_leaf->get_item( 'ACTIVE' )->set_type( if_salv_c_cell_type=>checkbox ).
        lo_salv_leaf->get_item( 'ACTIVE' )->set_checked( abap_true ).
        lo_salv_leaf->get_item( 'INSPECT' )->set_type( if_salv_c_cell_type=>button ).
        lo_salv_leaf->get_item( 'INSPECT' )->set_value( 'Inspect' ).
        IF mv_salv_tree_lazy147 = abap_true.
          lo_salv_tree->get_nodes( )->add_node(
            related_node = lo_salv_root->get_key( )
            data_row     = ls_tree_row
            text         = 'Lazy child: UA901 United' ).
        ENDIF.
        IF mv_salv_tree_added147 = abap_true.
          lo_salv_tree->get_nodes( )->add_node(
            related_node = lo_salv_root->get_key( )
            data_row     = ls_tree_row
            text         = 'Added leaf: AF010 Air France' ).
        ENDIF.
        IF mv_salv_tree_expanded147 = abap_false.
          lo_salv_root->collapse( ).
        ENDIF.
        lo_salv_tree->get_selections( )->set_selected_nodes(
          VALUE #( ( node_key = mv_salv_tree_selected147
                     node     = lo_salv_leaf ) ) ).
        IF mv_salv_tree_event147 CS 'link event'.
          lo_salv_tree->trigger_link_click(
            node_key   = 'NODE-2'
            columnname = 'FLIGHT' ).
        ELSEIF mv_salv_tree_event147 CS 'double-click'.
          lo_salv_tree->trigger_double_click(
            node_key   = 'NODE-2'
            columnname = 'FLIGHT' ).
        ENDIF.
        lo_salv_tree->display( ).
      CATCH cx_root INTO DATA(lx_error).
        ls_surface = table_surface( 'SALV tree fallback' ).
        ls_surface-text = |SALV tree construction failed safely: { lx_error->get_text( ) }; no native success is claimed|.
        zcl_gg_host_surface=>set_surface( ls_surface ).
    ENDTRY.
  ENDMETHOD.

  METHOD build_view.
    DATA lo_root TYPE REF TO cl_gui_custom_container.
    DATA lt_rows TYPE ty_rows.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_selected TYPE lvc_t_row.
    DATA ls_header TYPE treev_hhdr.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lo_alv_tree TYPE REF TO cl_gui_alv_tree.
    DATA lv_tree_key TYPE lvc_nkey.
    DATA lv_tree_root TYPE lvc_nkey.
    DATA ls_tree_row TYPE ty_row.
    DATA lo_root_graphic TYPE REF TO cl_gui_custom_container.
    DATA lo_alv_grid TYPE REF TO cl_gui_alv_grid.
    DATA ls_surface TYPE zcl_gg_host_surface=>ty_surface.

    lt_rows = VALUE #( ( carrier = 'Lufthansa' flight = 'LH400' seats = 180 active = 'X' inspect = 'Inspect' )
                       ( carrier = 'United' flight = 'UA901' seats = 210 active = 'X' inspect = 'Inspect' )
                       ( carrier = 'Air France' flight = 'AF010' seats = 160 active = space inspect = 'Inspect' ) ).
    CASE mv_mode.
      WHEN '135'.
        WHILE lines( lt_rows ) < mv_dynamic_generation + 2.
          APPEND VALUE #( carrier = |Generated { lines( lt_rows ) + 1 }|
                          flight  = |GG{ lines( lt_rows ) + 1 }|
                          seats   = 100 + lines( lt_rows ) * 10
                          active  = 'X'
                          inspect = 'Inspect' ) TO lt_rows.
        ENDWHILE.
      WHEN '136'.
        WHILE lines( lt_rows ) < mv_edit_row_count.
          APPEND VALUE #( carrier = |Draft { lines( lt_rows ) + 1 }|
                          flight  = |DRAFT{ lines( lt_rows ) + 1 }|
                          seats   = mv_edit_seats
                          active  = 'X'
                          inspect = 'Inspect' ) TO lt_rows.
        ENDWHILE.
        READ TABLE lt_rows ASSIGNING FIELD-SYMBOL(<edit_row>) INDEX 1.
        IF sy-subrc = 0.
          <edit_row>-seats = mv_edit_seats.
        ENDIF.
    ENDCASE.
    lt_fcat = VALUE #( ( fieldname = 'CARRIER' coltext = 'Carrier' outputlen = 14 emphasize = 'C310' )
                       ( fieldname = 'FLIGHT' coltext = 'Flight' outputlen = 10 icon = 'X' )
                       ( fieldname = 'SEATS' coltext = 'Seats' outputlen = 8 inttype = 'I' do_sum = 'X' ) ).

    CASE mv_mode.
      WHEN '135' OR '136' OR '137' OR '138' OR '139'.
        lo_root = NEW cl_gui_custom_container( container_name = |ROOT{ mv_mode }| ).
        lo_alv_grid = NEW cl_gui_alv_grid( i_parent = lo_root ).
        lo_alv_grid->set_gridtitle( i_gridtitle = COND #( WHEN mv_mode = '138' THEN 'Selectable flights' ELSE 'Flight capacity' ) ).
        IF mv_mode = '136'.
          lt_fcat = VALUE #(
            ( fieldname = 'CARRIER' coltext = 'Carrier' outputlen = 14 edit = 'X' f4availabl = 'X' )
            ( fieldname = 'FLIGHT' coltext = 'Flight' outputlen = 10 drdn_hndl = 1 )
            ( fieldname = 'SEATS' coltext = 'Seats' outputlen = 8 inttype = 'I' edit = 'X' do_sum = 'X' )
            ( fieldname = 'ACTIVE' coltext = 'Active' outputlen = 8 checkbox = 'X' edit = 'X' )
            ( fieldname = 'INSPECT' coltext = 'Inspect' outputlen = 10 hotspot = 'X' ) ).
        ENDIF.
        lo_alv_grid->set_table_for_first_display(
          CHANGING
            it_outtab       = lt_rows
            it_fieldcatalog = lt_fcat ).
        CASE mv_mode.
          WHEN '136'.
            lo_alv_grid->set_drop_down_table( it_drop_down = VALUE #(
              ( handle = 1 value = 'LH400' )
              ( handle = 1 value = 'UA901' )
              ( handle = 1 value = 'AF010' ) ) ).
            lo_alv_grid->register_f4_for_fields( it_f4 = VALUE #( ( fieldname = 'CARRIER' register = 'X' ) ) ).
            lo_alv_grid->set_ready_for_input( i_ready_for_input = 1 ).
          WHEN '139'.
            lo_alv_grid->register_delayed_event( i_event_id = cl_gui_alv_grid=>mc_evt_delayed_change_select ).
            lo_alv_grid->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
        ENDCASE.
        IF mv_mode = '135'.
          lo_alv_grid->set_frontend_layout( is_layout = VALUE lvc_s_layo( zebra = 'X' ) ).
          ls_surface = VALUE #(
            kind          = zcl_gg_host_surface=>surface_table
            aria_label    = 'Runtime ALV structure'
            table_caption = 'Generated dynamic structure'
            columns       = VALUE #( ( `Metadata` ) ( `Value` ) ( `State` ) )
            rows          = VALUE #(
              ( cell1 = 'Structure' cell2 = 'ZGG_DYNAMIC_FLIGHT_ROW' cell3 = |generation { mv_dynamic_generation }| )
              ( cell1 = 'Field catalog' cell2 = 'CARRIER, FLIGHT, SEATS' cell3 = 'runtime-created' )
              ( cell1 = 'Style component' cell2 = COND string( WHEN mv_dynamic_style = abap_true THEN 'STYLE' ELSE 'not requested' ) cell3 = 'server-owned' ) )
            text          = 'Dynamic table creation keeps the generated structure, field catalog, style component, and typed total metadata visible.'
            actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DYNAMIC_APPEND' label = 'Append runtime row' )
                                     ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DYNAMIC_STYLE' label = 'Toggle generated style' )
                                     ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DYNAMIC_INSPECT' label = 'Inspect structure' ) ) ).
          zcl_gg_host_surface=>set_surface( ls_surface ).
          zcl_gg_host_surface=>set_surface( VALUE #(
            kind          = zcl_gg_host_surface=>surface_table
            aria_label    = 'ALV presentation formats'
            table_caption = 'ALV colors and formats'
            columns       = VALUE #( ( `Row` ) ( `Amount` ) ( `Status` ) ( `Action` ) )
            rows          = VALUE #(
              ( cell1 = 'Lufthansa' cell2 = 'EUR 1,250.50' cell3 = 'Green traffic light' cell4 = 'Inspect'
                row_header = abap_true row_color = 'C310' row_style = 'emphasis'
                cell2_color = 'C210' cell2_style = 'currency' cell3_style = 'symbol' )
              ( cell1 = 'United' cell2 = 'USD 980.00' cell3 = 'Yellow traffic light' cell4 = 'Inspect'
                row_header = abap_true row_color = 'C510' row_style = 'warning'
                cell2_color = 'C210' cell2_style = 'currency' cell3_style = 'traffic' )
              ( cell1 = 'Air France' cell2 = '2026-08-30 12:00' cell3 = 'Information symbol' cell4 = 'Inspect'
                row_header = abap_true row_color = 'C210' row_style = 'date-time'
                cell2_style = 'date-time' cell3_style = 'symbol' ) )
            text          = 'Row and cell colors/styles, icons, traffic lights, symbols, currency, quantity, unit, date, and time formatting remain explicit metadata.'
            actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                       value = 'DYNAMIC_INSPECT' label = 'Inspect row 1' ) ) ) ).
        ENDIF.
        CASE mv_mode.
          WHEN '138'.
            lt_selected = VALUE #( ( index = 2 ) ).
            lo_alv_grid->set_selected_rows( it_index_rows = lt_selected ).
            ls_surface = table_surface( 'ALV row selection' ).
            ls_surface-token_label = 'Selected row token'.
            ls_surface-token_value = 'FLIGHT-2'.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'SELECT_ROW' label = 'Confirm selection' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '136'.
            ls_surface = table_surface( 'Editable ALV grid' ).
            ls_surface-input_label = 'Seats for LH400'.
            ls_surface-input_name = 'ALV-SEATS'.
            ls_surface-input_value = |{ mv_edit_seats }|.
            ls_surface-text = |{ mv_edit_status }; rows in memory: { mv_edit_row_count }|.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'SAVE_GRID' label = 'Save changed data' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'DISCARD_GRID' label = 'Discard draft' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'APPEND_ROW' label = 'Append row' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'COPY_ROW' label = 'Copy row' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'DELETE_ROW' label = 'Delete row' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'VALIDATE_GRID' label = 'Validate changes' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_F4' label = 'Carrier F4' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_HOTSPOT' label = 'Inspect hotspot' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '137'.
            ls_surface = table_surface( 'ALV sort and filter' ).
            ls_surface-criteria = 'Criteria: carrier contains Lufthansa; order by seats descending'.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'APPLY_CRITERIA' label = 'Apply criteria' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '139'.
            ls_surface = table_surface( 'ALV toolbar event' ).
            ls_surface-text = mv_event_last.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_EVENT' label = 'Application toolbar event' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_TOOLBAR' label = 'Toolbar event' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_MENU' label = 'Menu event' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_DELAYED' label = 'Delayed selection' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_PRINT' label = 'Print event' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_DATA_CHANGE' label = 'Data changed' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_DROP' label = 'Drag/drop event' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_APP_EVENT' label = 'Application event' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_HOTSPOT' label = 'Hotspot event' )
                                          ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_DOUBLE_CLICK' label = 'Double-click event' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
        ENDCASE.
      WHEN '140'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT140' ).
        DATA(lo_simple_tree) = NEW cl_gui_simple_tree( parent = lo_root ).
        lo_simple_tree->add_nodes( table_structure_name = 'TREEV_NODE'
                                   node_table           = VALUE string_table( ( `Root` ) ( `Editor` ) ( `Viewer` ) ) ).
        DATA(lv_tree_text) = 'Simple tree hierarchy with selection, item classes, expansion, and lazy-child state.'.
        IF mv_tree_compare140 = abap_true.
          DATA(lo_simple_model140) = NEW cl_simple_tree_model( ).
          lo_simple_model140->add_nodes( VALUE treemsnota(
            ( node_key = 'NODE-ROOT' expander = abap_true )
            ( node_key = 'NODE-LH400' relatkey = 'NODE-ROOT' ) ) ).
          DATA(lo_list_model140) = NEW cl_list_tree_model( with_headers = abap_true ).
          lo_list_model140->add_nodes( VALUE treemlnota(
            ( node_key = 'NODE-ROOT' isfolder = abap_true expander = abap_true )
            ( node_key = 'NODE-LH400' relatkey = 'NODE-ROOT' ) ) ).
          lv_tree_text = |Compare: { lo_simple_model140->get_state_summary( ) } vs { lo_list_model140->get_state_summary( ) }; opaque key NODE-LH400 retained.|.
        ELSEIF mv_tree_menu140 = abap_true.
          lv_tree_text = 'Context menu: Open details, Rename, and Remove are server-declared actions.'.
        ENDIF.
        ls_surface = VALUE #(
          kind        = zcl_gg_host_surface=>surface_tree
          aria_label  = 'Simple tree'
          nodes       = VALUE #(
            ( text = 'Flights' level = 1 node_key = 'NODE-ROOT' expanded = mv_tree_expanded140 icon = 'folder' item_class = 'text' )
            ( text = |LH400 { unicode_text( `E28094` ) } Lufthansa| level = 2 node_key = 'NODE-LH400' selected = xsdbool( mv_tree_selected140 = 'NODE-LH400' ) icon = 'flight' item_class = 'link' )
            ( text = 'Seats: 180' level = 3 node_key = 'NODE-SEATS' checked = abap_true icon = 'check' item_class = 'checkbox' hidden = xsdbool( mv_tree_expanded140 = abap_false ) )
            ( text = 'Carrier note' level = 3 node_key = 'NODE-NOTE' editable = abap_true icon = 'edit' item_class = 'editable' hidden = xsdbool( mv_tree_expanded140 = abap_false ) )
            ( text = 'Open details' level = 3 node_key = 'NODE-DETAIL' icon = 'display' item_class = 'button' hidden = xsdbool( mv_tree_expanded140 = abap_false ) )
            ( text = 'Lazy child: United' level = 2 node_key = 'NODE-LAZY' icon = 'folder' item_class = 'text' hidden = xsdbool( mv_tree_lazy140 = abap_false ) )
            ( text = 'Hidden audit node' level = 2 node_key = 'NODE-HIDDEN' hidden = abap_true ) )
          token_label = 'Opaque node key'
          token_value = mv_tree_selected140
          text        = lv_tree_text
          actions     = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'EXPAND_TREE' label = 'Expand tree' )
                                ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'COLLAPSE_TREE' label = 'Collapse tree' )
                                ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'SELECT_TREE' label = 'Select LH400' )
                                ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'LAZY_LOAD' label = 'Load children' )
                                ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'TREE_CONTEXT' label = 'Show context menu' )
                                ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'COMPARE_MODE' label = 'Compare models' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '141'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT141' ).
        DATA(lo_list_tree) = NEW cl_gui_list_tree( parent       = lo_root
                                                   with_headers = abap_true ).
        lo_list_tree->set_visible( abap_false ).
        lo_list_tree->hierarchy_header_set_text( 'Flight hierarchy' ).
        DATA(lo_column_tree) = NEW cl_gui_column_tree(
          parent                = lo_root
          node_selection_mode   = cl_tree_control_base=>node_sel_mode_single
          item_selection        = abap_true
          hierarchy_column_name = 'NAME'
          hierarchy_header      = ls_header ).
        lo_column_tree->set_visible( abap_false ).
        lo_column_tree->add_column( name        = 'STATUS'
                                    width       = 12
                                    header_text = 'Status' ).
        ls_surface = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'List and column trees'
          table_caption = 'Column tree'
          columns       = VALUE #( ( `Flight` ) ( `Status` ) )
          rows          = VALUE #(
            ( cell1 = 'Flights' cell2 = 'Expanded' row_header = abap_true )
            ( cell1 = 'LH400' cell2 = COND string( WHEN mv_tree_status_visible141 = abap_true THEN 'On time' ELSE '' ) row_header = abap_true ) )
          text          = 'Column tree preserves hierarchy headers, visibility, and typed item classes: text, checkbox, button, link, editable.'
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'TOGGLE_STATUS_COLUMN' label = 'Toggle status column' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'COLUMN_EXPAND' label = 'Expand hierarchy' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'COLUMN_SELECT' label = 'Select item' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind        = zcl_gg_host_surface=>surface_tree
          aria_label  = 'Column tree item classes'
          nodes       = VALUE #(
            ( text = 'Flights' level = 1 node_key = 'COLUMN-ROOT' expanded = abap_true icon = 'folder' item_class = 'text' )
            ( text = 'On time' level = 2 node_key = 'COLUMN-STATUS' icon = 'check' item_class = 'checkbox' checked = abap_true )
            ( text = 'Open LH400' level = 2 node_key = 'COLUMN-LINK' icon = 'link' item_class = 'link' )
            ( text = 'Edit carrier' level = 2 node_key = 'COLUMN-EDIT' icon = 'edit' item_class = 'editable' editable = abap_true )
            ( text = 'Inspect' level = 2 node_key = 'COLUMN-BUTTON' icon = 'display' item_class = 'button' ) )
          token_label = 'Opaque column node'
          token_value = 'COLUMN-LINK' ) ).
      WHEN '142'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT142' ).
        DATA(lo_event_tree) = NEW cl_gui_simple_tree( parent = lo_root ).
        lo_event_tree->add_nodes( table_structure_name = 'TREEV_NODE'
                                  node_table           = VALUE string_table( ( `Flights` ) ( `LH400` ) ) ).
        ls_surface = VALUE #(
          kind        = zcl_gg_host_surface=>surface_tree
          aria_label  = 'Interactive flight tree'
          nodes       = VALUE #(
            ( text = 'Flights' node_key = 'NODE-ROOT' expanded = abap_true )
            ( text = 'LH400' level = 2 node_key = 'NODE-LH400' ) )
          token_label = 'Opaque key'
          token_value = 'NODE-LH400'
          actions     = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                   value = 'TREE_SELECT' label = 'Select node' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '143'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT143' ).
        lo_alv_tree = NEW cl_gui_alv_tree( parent = lo_root ).
        lo_alv_tree->set_table_for_first_display( CHANGING it_outtab = lt_rows it_fieldcatalog = lt_fcat ).
        lo_alv_tree->add_node(
          EXPORTING
            i_relat_node_key = cl_alv_tree_base=>c_virtual_root_node
            i_relationship   = cl_tree_control_base=>relat_first_child
            i_node_text      = 'Flights'
          IMPORTING
            e_new_node_key   = lv_tree_key ).
        lv_tree_root = lv_tree_key.
        READ TABLE lt_rows INTO ls_tree_row INDEX 1.
        lo_alv_tree->add_node(
          EXPORTING
            i_relat_node_key = lv_tree_root
            i_relationship   = cl_tree_control_base=>relat_first_child
            is_outtab_line   = ls_tree_row
            i_node_text      = |LH400 { unicode_text( `E28094` ) } Lufthansa|
          IMPORTING
            e_new_node_key   = lv_tree_key ).
        IF mv_tree_lazy143 = abap_true.
          lo_alv_tree->add_node(
            EXPORTING
              i_relat_node_key = lv_tree_root
              i_relationship   = cl_tree_control_base=>relat_last_child
              is_outtab_line   = ls_tree_row
              i_node_text      = 'Lazy child: UA901 United'
            IMPORTING
              e_new_node_key   = lv_tree_key ).
        ENDIF.
        IF mv_tree_added143 = abap_true.
          lo_alv_tree->add_node(
            EXPORTING
              i_relat_node_key = lv_tree_root
              i_relationship   = cl_tree_control_base=>relat_last_child
              is_outtab_line   = ls_tree_row
              i_node_text      = 'Added leaf: AF010 Air France'
            IMPORTING
              e_new_node_key   = lv_tree_key ).
        ENDIF.
        IF mv_tree_expanded143 = abap_false.
          lo_alv_tree->collapse_subtree( i_node_key = lv_tree_root ).
        ENDIF.
        ls_surface = VALUE #(
          kind = zcl_gg_host_surface=>surface_caption
          text = 'Hierarchy columns: Flight, Carrier, Seats' ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
        ls_surface = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'ALV tree semantic rows'
          table_caption = 'ALV tree hierarchy and typed columns'
          columns       = VALUE #( ( `Hierarchy` ) ( `Carrier` ) ( `Flight` ) ( `Seats` ) )
          rows          = VALUE #(
            ( cell1 = 'Flights' cell2 = '-' cell3 = '-' cell4 = '-' row_header = abap_true )
            ( cell1 = |LH400 { unicode_text( `E28094` ) } Lufthansa| cell2 = 'Lufthansa' cell3 = 'LH400' cell4 = '180' row_header = abap_true )
            ( cell1 = 'Lazy child: UA901 United' cell2 = 'United' cell3 = 'UA901' cell4 = '210' row_header = abap_true )
            ( cell1 = 'Added leaf: AF010 Air France' cell2 = 'Air France' cell3 = 'AF010' cell4 = '160' row_header = abap_true ) )
          data_value    = 'Total seats: 550'
          token_label   = 'Selected node'
          token_value   = mv_tree_selected143
          text          = |{ mv_tree_event143 }; hierarchy, lazy children, node/item events, mutation, selection, and typed totals remain server-owned.| ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '147'.
        build_salv_tree( lt_rows ).
      WHEN '144' OR '145' OR '146'.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_salv CHANGING t_table = lt_rows ).
        lo_salv->set_list_header( COND #( WHEN mv_mode = '146' THEN 'SALV header and layout' ELSE 'SALV flights' ) ).
        lo_salv->display( ).
        CASE mv_mode.
          WHEN '144'.
            ls_surface = table_surface( 'SALV table basics' ).
            ls_surface-text = 'Functions: sort, filter, export'.
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '145'.
            ls_surface = table_surface( 'SALV sort filter aggregation' ).
            ls_surface-data_value = 'Total seats: 550'.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'SALV_FILTER' label = 'Apply server filter' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '146'.
            DATA(lo_header) = NEW cl_salv_form_header_info( text = 'Flight capacity report' ).
            DATA(lo_layout) = NEW cl_salv_form_layout_grid( columns = 2 ).
            lo_layout->set_column_label_for( label_column = 1
                                             text_column  = 2 ).
            ls_surface = table_surface( 'SALV header and layout' ).
            ls_surface-kind = zcl_gg_host_surface=>surface_salv_layout.
            ls_surface-title = 'Flight capacity report'.
            ls_surface-text = 'Prepared by the analytics team | Run date: 2026-08-30'.
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '147'.
            ls_surface = table_surface( 'SALV selections and events' ).
            ls_surface-token_label = 'Double-click event token'.
            ls_surface-token_value = 'ROW-2'.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'SALV_LINK' label = 'Open LH400' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
        ENDCASE.
      WHEN '148'.
        lo_root_graphic = NEW cl_gui_custom_container( container_name = 'ROOT148' ).
        DATA(lo_bar148) = NEW cl_gui_barchart( parent = lo_root_graphic ).
        lo_bar148->set_position( left   = 20
                                 top    = 20
                                 width  = 420
                                 height = 180 ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind        = zcl_gg_host_surface=>surface_chart
          aria_label  = 'Bar chart'
          title       = 'Flights by carrier'
          input_label = 'Series color'
          input_name  = 'CHART_COLOR'
          input_type  = 'color'
          input_value = mv_chart_color
          text        = 'Native CL_GUI_BARCHART is unavailable in the browser; values remain available as an accessible table fallback.'
          columns     = VALUE #( ( `Carrier` ) ( `Flights` ) )
          rows        = VALUE #( ( cell1 = 'Lufthansa' cell2 = '42' row_header = abap_true )
                                ( cell1 = 'United' cell2 = '31' row_header = abap_true ) )
          actions     = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                  value = 'SET_CHART_COLOR' label = 'Apply color' ) ) ) ).
      WHEN '149'.
        lo_root_graphic = NEW cl_gui_custom_container( container_name = 'ROOT149' ).
        DATA(lo_engine149) = NEW cl_gui_chart_engine( parent = lo_root_graphic ).
        lo_engine149->set_data( data = 'series=flights;values=42,31' ).
        lo_engine149->render( ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind       = zcl_gg_host_surface=>surface_chart
          aria_label = 'Chart engine fallback'
          title      = 'Graphic presentation: monthly load'
          text       = 'Native CL_GUI_CHART_ENGINE is unavailable in the browser; deterministic chart data remains available as an accessible table fallback.'
          payload    = 'series=flights'
          columns    = VALUE #( ( `Month` ) ( `Load` ) )
          rows       = VALUE #( ( cell1 = 'August' cell2 = '82%' row_header = abap_true )
                                ( cell1 = 'September' cell2 = '76%' row_header = abap_true ) ) ) ).
    ENDCASE.
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

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( |ZCL_GG_EX_{ mv_mode }| ).
    set_status( io_session ).
    build_view( io_session ).
    write_line( io_session = io_session
                iv_text    = |Structured table/tree example { mv_mode }| ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    rs_settings = VALUE #( title = |ZCL_GG_EX_{ mv_mode }| status = 'STRUCTURED DATA' ).
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

  METHOD zif_gg_list_processing_v1~at_user_command.
    CASE mv_mode.
      WHEN '135' OR '136' OR '139'.
        handle_alv_command( io_session = io_session
                            iv_ucomm   = iv_ucomm ).
      WHEN '137'.
        IF iv_ucomm = 'APPLY_CRITERIA'.
          mv_filtered = abap_true.
          mv_sorted = abap_true.
          set_status( io_session ).
          write_line( io_session = io_session
                      iv_text    = 'ALV criteria applied server-side' ).
        ENDIF.
      WHEN '138'.
        IF iv_ucomm = 'SELECT_ROW'.
          write_line( io_session = io_session
                      iv_text    = 'Selected opaque row FLIGHT-2' ).
        ENDIF.
      WHEN '140' OR '141'.
        cl_gui_control=>clear( ).
        zcl_gg_host_surface=>clear( ).
        handle_tree_command( io_session = io_session
                             iv_ucomm   = iv_ucomm ).
        build_view( io_session ).
        set_status( io_session ).
        write_line( io_session = io_session
                    iv_text    = |Tree action { iv_ucomm } applied to server-owned state| ).
      WHEN '142'.
        IF iv_ucomm = 'TREE_SELECT'.
          write_line( io_session = io_session
                      iv_text    = 'Tree node NODE-LH400 selected' ).
        ENDIF.
      WHEN '143'.
        cl_gui_control=>clear( ).
        zcl_gg_host_surface=>clear( ).
        handle_tree_command( io_session = io_session
                             iv_ucomm   = iv_ucomm ).
        build_view( io_session ).
        set_status( io_session ).
        write_line( io_session = io_session
                    iv_text    = |ALV tree action { iv_ucomm } applied| ).
      WHEN '145'.
        IF iv_ucomm = 'SALV_FILTER'.
          mv_filtered = abap_true.
          set_status( io_session ).
          write_line( io_session = io_session
                      iv_text    = 'SALV filter applied; total remains server-owned' ).
        ENDIF.
      WHEN '147'.
        cl_gui_control=>clear( ).
        zcl_gg_host_surface=>clear( ).
        handle_tree_command( io_session = io_session
                             iv_ucomm   = iv_ucomm ).
        build_view( io_session ).
        set_status( io_session ).
        write_line( io_session = io_session
                    iv_text    = |SALV tree action { iv_ucomm } applied; { mv_salv_tree_event147 }| ).
      WHEN '148'.
        IF iv_ucomm = 'SET_CHART_COLOR'.
          DATA(lv_chart_color) = request_value( io_session = io_session
                                                iv_name    = 'CHART_COLOR' ).
          IF strlen( lv_chart_color ) = 7
              AND lv_chart_color(1) = '#'.
            DATA(lv_hex) = lv_chart_color+1(6).
            TRANSLATE lv_hex TO UPPER CASE.
            IF lv_hex CO '0123456789ABCDEF'.
              mv_chart_color = |#{ lv_hex }|.
            ENDIF.
          ENDIF.
          cl_gui_control=>clear( ).
          zcl_gg_host_surface=>clear( ).
          write_line( io_session = io_session
                      iv_text    = |Chart color set to { mv_chart_color }; native graphic remains an accessible table fallback| ).
          build_view( io_session ).
          set_status( io_session ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
