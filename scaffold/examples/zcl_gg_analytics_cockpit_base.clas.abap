CLASS zcl_gg_analytics_cockpit_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Composite example 150. Selection values, control state, and commands remain
* server-owned while the browser receives only rendered control snapshots.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.
    INTERFACES zif_gg_resumable_v1.

  PRIVATE SECTION.
    DATA mv_saved TYPE abap_bool.
    DATA mv_carrier TYPE string.
    DATA mv_date TYPE string.

    METHODS write_line
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_text    TYPE string.

    METHODS render_cockpit
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.
ENDCLASS.

CLASS zcl_gg_analytics_cockpit_base IMPLEMENTATION.

  METHOD write_line.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = iv_text
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name      = 'P_CARR'
      text      = 'Carrier filter'
      data_type = VALUE #( typ = 'C' length = 20 )
      default   = 'Lufthansa' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_DATE'
      text      = 'As-of date'
      data_type = VALUE #( typ = 'D' length = 8 )
      default   = '20260830' ) ).
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
    READ TABLE ct_values INTO DATA(ls_carrier) WITH KEY name = 'P_CARR'.
    IF sy-subrc = 0.
      mv_carrier = ls_carrier-value.
    ENDIF.
    READ TABLE ct_values INTO DATA(ls_date) WITH KEY name = 'P_DATE'.
    IF sy-subrc = 0.
      mv_date = ls_date-value.
    ENDIF.
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
* The host sends the declared selection screen before START-OF-SELECTION, so
* the filters are already in ct_values by the time the cockpit renders. This
* used to call selection screen 1000 itself, guarded by a one-shot flag.
    render_cockpit( io_session ).
  ENDMETHOD.

  METHOD render_cockpit.
    DATA lo_root TYPE REF TO cl_gui_custom_container.
    DATA lt_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_nodes TYPE string_table.

    io_session->get_list( )->set_title( 'ZCL_GG_EX_150 Analytics cockpit' ).
    io_session->get_list( )->set_status( VALUE #(
      status       = COND #( WHEN mv_saved = abap_true THEN 'FILTERS SAVED' ELSE 'COCKPIT READY' )
      active_ucomm = VALUE #( ( 'SAVE_FILTERS' ) ( 'OPEN_DETAIL' ) )
      icon_bar     = VALUE #(
        ( ucomm = 'SAVE_FILTERS' label = 'Save filters' icon = 'save' )
        ( ucomm = 'OPEN_DETAIL' label = 'Open detail' icon = 'display' ) ) ) ).

    lo_root = NEW cl_gui_custom_container( container_name = 'COCKPIT150' ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_root ).
    APPEND |{ mv_carrier }| TO lt_rows.
    APPEND 'United' TO lt_rows.
    APPEND VALUE #( fieldname = 'VALUE' coltext = 'Carrier result' outputlen = 24 ) TO lt_fcat.
    lo_grid->set_gridtitle( 'Filtered flight summary' ).
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).

    DATA(lo_tree) = NEW cl_gui_simple_tree( parent = lo_root ).
    lt_nodes = VALUE #( ( `Summary` ) ( `Capacity` ) ( `Details` ) ).
    lo_tree->add_nodes( table_structure_name = 'TREEV_NODE'
                        node_table           = lt_nodes ).

    DATA(lo_chart) = NEW cl_gui_chart_engine( parent = lo_root ).
    lo_chart->set_data( data = |carrier={ mv_carrier };date={ mv_date };load=82| ).
    lo_chart->render( ).

    DATA(lo_detail) = NEW cl_gui_textedit( parent                     = lo_root
                                           wordwrap_to_linebreak_mode = 0 ).
    lo_detail->set_textstream( |Detail dynpro pane{ cl_abap_char_utilities=>newline }{ mv_carrier } / { mv_date }| ).
    lo_detail->set_position( left   = 20
                             top    = 220
                             width  = 420
                             height = 80 ).

    zcl_gg_host_surface=>set_surface( VALUE #(
      kind       = zcl_gg_host_surface=>surface_cockpit
      aria_label = 'Analytics cockpit'
      title      = 'Analytics cockpit'
      text       = 'ALV table, tree navigation, chart summary, and detail dynpro pane share server-owned state.'
      data_value = mv_carrier
      payload    = mv_date
      actions    = VALUE #(
        ( transport = zcl_gg_host_surface=>surface_action_command value = 'SAVE_FILTERS' label = 'Save filters' )
        ( transport = zcl_gg_host_surface=>surface_action_command value = 'OPEN_DETAIL' label = 'Open detail dynpro' ) ) ) ).
    write_line( io_session = io_session
                iv_text    = |Cockpit filters: { mv_carrier } / { mv_date }| ).
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_FILTERS'.
      render_cockpit( io_session ).
      write_line( io_session = io_session
                  iv_text    = |Cockpit filters: { mv_carrier } / { mv_date }| ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    rs_settings = VALUE #( title = 'ZCL_GG_EX_150 Analytics cockpit' status = 'COCKPIT' ).
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
    CASE iv_ucomm.
      WHEN 'SAVE_FILTERS'.
        mv_saved = abap_true.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'FILTERS SAVED'
          active_ucomm = VALUE #( ( 'SAVE_FILTERS' ) ( 'OPEN_DETAIL' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'SAVE_FILTERS' label = 'Save filters' icon = 'save' )
            ( ucomm = 'OPEN_DETAIL' label = 'Open detail' icon = 'display' ) ) ) ).
        write_line( io_session = io_session
                    iv_text    = 'Cockpit filters saved on the server' ).
      WHEN 'OPEN_DETAIL'.
        write_line( io_session = io_session
                    iv_text    = 'Detail dynpro opened from cockpit' ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
