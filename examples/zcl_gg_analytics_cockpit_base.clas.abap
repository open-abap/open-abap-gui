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
    DATA lt_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    io_session->get_list( )->set_title( 'ZCL_GG_EX_150 Analytics cockpit' ).
    io_session->get_list( )->set_status( VALUE #(
      status       = COND #( WHEN mv_saved = abap_true THEN 'FILTERS SAVED' ELSE 'COCKPIT READY' )
      active_ucomm = VALUE #( ( 'SAVE_FILTERS' ) ( 'OPEN_DETAIL' ) ( 'RUN_LAYOUT' )
                              ( 'REFRESH_COCKPIT' ) ( 'SELECT_TREE' ) )
      icon_bar     = VALUE #(
        ( ucomm = 'SAVE_FILTERS' label = 'Save filters' icon = 'save' )
        ( ucomm = 'OPEN_DETAIL' label = 'Open detail' icon = 'display' )
        ( ucomm = 'REFRESH_COCKPIT' label = 'Refresh cockpit' icon = 'refresh' ) ) ) ).

    lo_root = NEW cl_gui_custom_container( container_name = 'COCKPIT150' ).
    DATA(lo_layout) = NEW cl_gui_splitter_container( parent  = lo_root
                                                     rows    = 2
                                                     columns = 1 ).
    lo_layout->set_position( left   = 8
                             top    = 8
                             width  = 980
                             height = 360 ).
    DATA(lo_upper) = lo_layout->get_container(
      row    = 1
      column = 1 ).
    DATA(lo_lower) = lo_layout->get_container(
      row    = 2
      column = 1 ).
    DATA(lo_application_toolbar) = NEW cl_gui_toolbar( parent = lo_upper ).
    lo_application_toolbar->add_button(
      fcode     = 'RUN_LAYOUT'
      icon      = '@'
      butn_type = 0
      text      = 'Run layout' ).
    lo_application_toolbar->add_button(
      fcode     = 'REFRESH_COCKPIT'
      icon      = '@'
      butn_type = 0
      text      = 'Refresh cockpit' ).
    lo_application_toolbar->add_button(
      fcode     = 'SELECT_TREE'
      icon      = '@'
      butn_type = 0
      text      = 'Select tree' ).
    lo_application_toolbar->set_position( left   = 8
                                          top    = 8
                                          width  = 360
                                          height = 28 ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_upper ).
    APPEND |{ mv_carrier }| TO lt_rows.
    APPEND 'United' TO lt_rows.
    APPEND VALUE #( fieldname = 'VALUE' coltext = 'Carrier result' outputlen = 24 ) TO lt_fcat.
    lo_grid->set_gridtitle( 'Filtered flight summary' ).
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).
    lo_grid->set_position( left   = 8
                           top    = 44
                           width  = 360
                           height = 110 ).

    DATA(lo_tree) = NEW cl_gui_simple_tree( parent = lo_upper ).
    lt_nodes = VALUE #( ( `Summary` ) ( `Capacity` ) ( `Details` ) ).
    lo_tree->add_nodes( table_structure_name = 'TREEV_NODE'
                        node_table           = lt_nodes ).
    lo_tree->set_position( left   = 390
                           top    = 44
                           width  = 220
                           height = 110 ).

    DATA(lo_chart) = NEW cl_gui_chart_engine( parent = lo_upper ).
    lo_chart->set_data( data = |carrier={ mv_carrier };date={ mv_date };load=82| ).
    lo_chart->render( ).
    lo_chart->set_position( left   = 630
                            top    = 44
                            width  = 280
                            height = 110 ).

    DATA(lo_detail_split) = NEW cl_gui_splitter_container( parent  = lo_lower
                                                           rows    = 1
                                                           columns = 2 ).
    DATA(lo_detail_pane) = lo_detail_split->get_container(
      row    = 1
      column = 1 ).
    DATA(lo_detail_view) = lo_detail_split->get_container(
      row    = 1
      column = 2 ).
    DATA(lo_detail) = NEW cl_gui_textedit( parent                     = lo_detail_pane
                                           wordwrap_to_linebreak_mode = 0 ).
    lo_detail->set_textstream( |Detail dynpro pane{ cl_abap_char_utilities=>newline }{ mv_carrier } / { mv_date }| ).
    lo_detail->set_position( left   = 20
                             top    = 220
                             width  = 420
                             height = 80 ).
    DATA(lo_detail_viewer) = NEW cl_gui_html_viewer( parent = lo_detail_view ).
    lt_html = VALUE #( ( CONV string( '<h3>Detail viewer</h3><p>Nested cockpit content remains available.</p>' ) ) ).
    lo_detail_viewer->load_data( CHANGING data_table = lt_html ).

    zcl_gg_host_surface=>set_surface( VALUE #(
      kind       = zcl_gg_host_surface=>surface_cockpit
      aria_label = 'Analytics cockpit'
      title      = 'Analytics cockpit'
      text       = 'Application toolbar, ALV table, tree navigation, chart summary, nested editor/viewer panes, and bottom actions share server-owned state.'
      data_value = mv_carrier
      payload    = mv_date
      actions    = VALUE #(
        ( transport = zcl_gg_host_surface=>surface_action_command value = 'SAVE_FILTERS' label = 'Save filters' )
        ( transport = zcl_gg_host_surface=>surface_action_command value = 'OPEN_DETAIL' label = 'Open detail dynpro' )
        ( transport = zcl_gg_host_surface=>surface_action_command value = 'RUN_LAYOUT' label = 'Run layout' )
        ( transport = zcl_gg_host_surface=>surface_action_command value = 'REFRESH_COCKPIT' label = 'Refresh cockpit' )
        ( transport = zcl_gg_host_surface=>surface_action_command value = 'SELECT_TREE' label = 'Select tree' ) ) ) ).
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
      WHEN 'RUN_LAYOUT'.
        write_line( io_session = io_session
                    iv_text    = 'Composite layout run completed with nested panes' ).
      WHEN 'REFRESH_COCKPIT'.
        write_line( io_session = io_session
                    iv_text    = 'Cockpit refreshed without losing tree or editor state' ).
      WHEN 'SELECT_TREE'.
        write_line( io_session = io_session
                    iv_text    = 'Tree selection applied to the ALV detail context' ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
