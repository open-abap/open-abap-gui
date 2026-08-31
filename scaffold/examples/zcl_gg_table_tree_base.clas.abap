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
           END OF ty_row.
    TYPES ty_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.

    DATA mv_mode TYPE string.
    DATA mv_action_count TYPE i.
    DATA mv_sorted TYPE abap_bool.
    DATA mv_filtered TYPE abap_bool.

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

    METHODS table_surface
      IMPORTING
        iv_label          TYPE string
      RETURNING
        VALUE(rs_surface) TYPE zcl_gg_host_surface=>ty_surface.

    CLASS-METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_table_tree_base IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD write_line.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = iv_text
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD unicode_text.
    DATA(lv_utf8) = CONV xstring( iv_hex ).
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input = lv_utf8 encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = rv_text ).
  ENDMETHOD.

  METHOD set_status.
    CASE mv_mode.
      WHEN '136'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'EDITABLE ALV'
          active_ucomm = VALUE #( ( 'SAVE_GRID' ) )
          icon_bar = VALUE #( ( ucomm = 'SAVE_GRID' label = 'Save grid' icon = 'save' ) ) ) ).
      WHEN '137'.
        io_session->get_list( )->set_status( VALUE #(
          status = COND #( WHEN mv_filtered = abap_true THEN 'FILTERED'
                           WHEN mv_sorted = abap_true THEN 'SORTED'
                           ELSE 'ALV CRITERIA' )
          active_ucomm = VALUE #( ( 'APPLY_CRITERIA' ) )
          icon_bar = VALUE #( ( ucomm = 'APPLY_CRITERIA' label = 'Apply criteria' icon = 'filter' ) ) ) ).
      WHEN '138'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'ALV SELECTION'
          active_ucomm = VALUE #( ( 'SELECT_ROW' ) )
          icon_bar = VALUE #( ( ucomm = 'SELECT_ROW' label = 'Select row' icon = 'select-all' ) ) ) ).
      WHEN '139'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'ALV EVENTS'
          active_ucomm = VALUE #( ( 'ALV_EVENT' ) )
          icon_bar = VALUE #( ( ucomm = 'ALV_EVENT' label = 'Run event' icon = 'event' ) ) ) ).
      WHEN '142'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'TREE EVENTS'
          active_ucomm = VALUE #( ( 'TREE_SELECT' ) )
          icon_bar = VALUE #( ( ucomm = 'TREE_SELECT' label = 'Select node' icon = 'select-all' ) ) ) ).
      WHEN '145'.
        io_session->get_list( )->set_status( VALUE #(
          status = COND #( WHEN mv_filtered = abap_true THEN 'SALV FILTERED' ELSE 'SALV TOTALS' )
          active_ucomm = VALUE #( ( 'SALV_FILTER' ) )
          icon_bar = VALUE #( ( ucomm = 'SALV_FILTER' label = 'Filter SALV' icon = 'filter' ) ) ) ).
      WHEN '147'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'SALV EVENTS'
          active_ucomm = VALUE #( ( 'SALV_LINK' ) )
          icon_bar = VALUE #( ( ucomm = 'SALV_LINK' label = 'Open row' icon = 'link' ) ) ) ).
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

  METHOD build_view.
    DATA lo_root TYPE REF TO cl_gui_custom_container.
    DATA lt_rows TYPE ty_rows.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_selected TYPE lvc_t_row.
    DATA ls_header TYPE treev_hhdr.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lo_alv_tree TYPE REF TO cl_gui_alv_tree.
    DATA lv_tree_key TYPE lvc_nkey.
    DATA lo_root_graphic TYPE REF TO cl_gui_custom_container.
    DATA ls_surface TYPE zcl_gg_host_surface=>ty_surface.

    lt_rows = VALUE #( ( carrier = 'Lufthansa' flight = 'LH400' seats = 180 )
                       ( carrier = 'United' flight = 'UA901' seats = 210 )
                       ( carrier = 'Air France' flight = 'AF010' seats = 160 ) ).
    lt_fcat = VALUE #( ( fieldname = 'CARRIER' coltext = 'Carrier' outputlen = 14 )
                       ( fieldname = 'FLIGHT' coltext = 'Flight' outputlen = 10 )
                       ( fieldname = 'SEATS' coltext = 'Seats' outputlen = 8 ) ).

    CASE mv_mode.
      WHEN '135' OR '136' OR '137' OR '138' OR '139'.
        lo_root = NEW cl_gui_custom_container( container_name = |ROOT{ mv_mode }| ).
        DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_root ).
        lo_grid->set_gridtitle( i_gridtitle = COND #( WHEN mv_mode = '138' THEN 'Selectable flights' ELSE 'Flight capacity' ) ).
        lo_grid->set_table_for_first_display(
          CHANGING
            it_outtab      = lt_rows
            it_fieldcatalog = lt_fcat ).
        CASE mv_mode.
          WHEN '138'.
            lt_selected = VALUE #( ( index = 2 ) ).
            lo_grid->set_selected_rows( it_index_rows = lt_selected ).
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
            ls_surface-input_value = '180'.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'SAVE_GRID' label = 'Save changed data' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '137'.
            ls_surface = table_surface( 'ALV sort and filter' ).
            ls_surface-criteria = 'Criteria: carrier contains Lufthansa; order by seats descending'.
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'APPLY_CRITERIA' label = 'Apply criteria' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
          WHEN '139'.
            ls_surface = table_surface( 'ALV toolbar event' ).
            ls_surface-actions = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                            value = 'ALV_EVENT' label = 'Application toolbar event' ) ).
            zcl_gg_host_surface=>set_surface( ls_surface ).
        ENDCASE.
      WHEN '140'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT140' ).
        DATA(lo_simple_tree) = NEW cl_gui_simple_tree( parent = lo_root ).
        lo_simple_tree->add_nodes( table_structure_name = 'TREEV_NODE' node_table = VALUE string_table( ( `Root` ) ( `Editor` ) ( `Viewer` ) ) ).
        ls_surface = VALUE #(
          kind       = zcl_gg_host_surface=>surface_tree
          aria_label = 'Simple tree'
          nodes      = VALUE #(
            ( text = 'Flights' level = 1 expanded = abap_true )
            ( text = |LH400 { unicode_text( `E28094` ) } Lufthansa| level = 2 )
            ( text = 'Hidden audit node' level = 2 hidden = abap_true ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '141'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT141' ).
        DATA(lo_list_tree) = NEW cl_gui_list_tree( parent = lo_root with_headers = abap_true ).
        lo_list_tree->hierarchy_header_set_text( 'Flight hierarchy' ).
        DATA(lo_column_tree) = NEW cl_gui_column_tree(
          parent = lo_root
          node_selection_mode = cl_tree_control_base=>node_sel_mode_single
          item_selection = abap_true
          hierarchy_column_name = 'NAME'
          hierarchy_header = ls_header ).
        lo_column_tree->add_column( name = 'STATUS' width = 12 header_text = 'Status' ).
        ls_surface = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'List and column trees'
          table_caption = 'Column tree'
          columns       = VALUE #( ( `Flight` ) ( `Status` ) )
          rows          = VALUE #(
            ( cell1 = 'Flights' cell2 = 'Expanded' row_header = abap_true )
            ( cell1 = 'LH400' cell2 = 'On time' row_header = abap_true ) ) ).
        zcl_gg_host_surface=>set_surface( ls_surface ).
      WHEN '142'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT142' ).
        DATA(lo_event_tree) = NEW cl_gui_simple_tree( parent = lo_root ).
        lo_event_tree->add_nodes( table_structure_name = 'TREEV_NODE' node_table = VALUE string_table( ( `Flights` ) ( `LH400` ) ) ).
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
        lo_alv_tree->add_node(
          EXPORTING
            i_relat_node_key = lv_tree_key
            i_relationship   = cl_tree_control_base=>relat_first_child
            i_node_text      = |LH400 { unicode_text( `E28094` ) } Lufthansa|
          IMPORTING
            e_new_node_key   = lv_tree_key ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind = zcl_gg_host_surface=>surface_caption
          text = 'Hierarchy columns: Flight, Carrier, Seats' ) ).
      WHEN '144' OR '145' OR '146' OR '147'.
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
            lo_layout->set_column_label_for( label_column = 1 text_column = 2 ).
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
        lo_bar148->set_position( left = 20 top = 20 width = 420 height = 180 ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind       = zcl_gg_host_surface=>surface_chart
          aria_label = 'Bar chart'
          title      = 'Flights by carrier'
          columns    = VALUE #( ( `Carrier` ) ( `Flights` ) )
          rows       = VALUE #( ( cell1 = 'Lufthansa' cell2 = '42' row_header = abap_true )
                                ( cell1 = 'United' cell2 = '31' row_header = abap_true ) ) ) ).
      WHEN '149'.
        lo_root_graphic = NEW cl_gui_custom_container( container_name = 'ROOT149' ).
        DATA(lo_engine149) = NEW cl_gui_chart_engine( parent = lo_root_graphic ).
        lo_engine149->set_data( data = 'series=flights;values=42,31' ).
        lo_engine149->render( ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind       = zcl_gg_host_surface=>surface_chart
          aria_label = 'Chart engine fallback'
          title      = 'Graphic presentation: monthly load'
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
    write_line( io_session = io_session iv_text = |Structured table/tree example { mv_mode }| ).
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
      WHEN '136'.
        IF iv_ucomm = 'SAVE_GRID'.
          mv_action_count = mv_action_count + 1.
          write_line( io_session = io_session iv_text = |ALV changed data accepted ({ mv_action_count })| ).
        ENDIF.
      WHEN '137'.
        IF iv_ucomm = 'APPLY_CRITERIA'.
          mv_filtered = abap_true.
          mv_sorted = abap_true.
          set_status( io_session ).
          write_line( io_session = io_session iv_text = 'ALV criteria applied server-side' ).
        ENDIF.
      WHEN '138'.
        IF iv_ucomm = 'SELECT_ROW'.
          write_line( io_session = io_session iv_text = 'Selected opaque row FLIGHT-2' ).
        ENDIF.
      WHEN '139'.
        IF iv_ucomm = 'ALV_EVENT'.
          write_line( io_session = io_session iv_text = 'ALV toolbar event delivered' ).
        ENDIF.
      WHEN '142'.
        IF iv_ucomm = 'TREE_SELECT'.
          write_line( io_session = io_session iv_text = 'Tree node NODE-LH400 selected' ).
        ENDIF.
      WHEN '145'.
        IF iv_ucomm = 'SALV_FILTER'.
          mv_filtered = abap_true.
          set_status( io_session ).
          write_line( io_session = io_session iv_text = 'SALV filter applied; total remains server-owned' ).
        ENDIF.
      WHEN '147'.
        IF iv_ucomm = 'SALV_LINK'.
          write_line( io_session = io_session iv_text = 'SALV link event for ROW-2' ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
