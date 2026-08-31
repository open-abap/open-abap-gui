CLASS zcl_gg_control_showcase_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared report implementation for the GUI-control examples 117-134. The
* numbered classes select one snapshot family and publish transaction data.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.
    DATA mv_refresh TYPE i.

    METHODS build_controls
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.

    METHODS set_status
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.

    METHODS write_line
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_text    TYPE string.

    CLASS-METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_control_showcase_base IMPLEMENTATION.

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
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input    = lv_utf8
                                                     encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = rv_text ).
  ENDMETHOD.

  METHOD build_controls.
    DATA lo_root TYPE REF TO cl_gui_custom_container.
    DATA lt_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_nodes TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lo_viewer128 TYPE REF TO cl_gui_html_viewer.
    DATA lo_viewer134 TYPE REF TO cl_gui_html_viewer.
    DATA lv_picture_result124 TYPE i.

    CASE mv_mode.
      WHEN '117'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT117' ).
        DATA(lo_editor117) = NEW cl_gui_textedit( parent                     = lo_root
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor117->set_textstream( 'Child control in custom container' ).
        lo_editor117->set_position( left   = 20
                                    top    = 30
                                    width  = 360
                                    height = 80 ).
      WHEN '118'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT118' ).
        DATA(lo_split118) = NEW cl_gui_splitter_container( parent  = lo_root
                                                           rows    = 2
                                                           columns = 1 ).
        lo_split118->set_position( left   = 10
                                   top    = 10
                                   width  = 500
                                   height = 240 ).
        DATA(lo_nested118) = NEW cl_gui_splitter_container( parent  = lo_split118
                                                            rows    = 1
                                                            columns = 2 ).
        DATA(lo_editor118) = NEW cl_gui_textedit( parent                     = lo_nested118
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor118->set_textstream( 'Nested horizontal pane' ).
      WHEN '119'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT119' ).
        DATA(lo_easy119) = NEW cl_gui_easy_splitter_container( parent        = lo_root
                                                               orientation   = cl_gui_easy_splitter_container=>orientation_horizontal
                                                               sash_position = 40 ).
        lo_easy119->set_position( left   = 10
                                  top    = 10
                                  width  = 500
                                  height = 180 ).
        DATA(lo_editor119) = NEW cl_gui_textedit( parent                     = lo_easy119
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor119->set_textstream( 'Easy splitter content' ).
      WHEN '120'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT120' ).
        DATA(lo_dock120) = NEW cl_gui_docking_container( parent    = lo_root
                                                         side      = cl_gui_docking_container=>dock_at_right
                                                         extension = 180
                                                         caption   = 'Docked tools' ).
        lo_dock120->set_position( left   = 330
                                  top    = 10
                                  width  = 180
                                  height = 160 ).
        DATA(lo_editor120) = NEW cl_gui_textedit( parent                     = lo_dock120
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor120->set_textstream( 'Docked content' ).
      WHEN '121'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT121' ).
        DATA(lo_dialog121) = NEW cl_gui_dialogbox_container( parent  = lo_root
                                                             width   = 360
                                                             height  = 180
                                                             caption = 'Dialog content' ).
        DATA(lo_editor121) = NEW cl_gui_textedit( parent                     = lo_dialog121
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor121->set_textstream( 'Modal dialog body' ).
      WHEN '122'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT122' ).
        DATA(lo_editor122) = NEW cl_gui_textedit( parent                     = lo_root
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor122->set_textstream( |First line{ cl_abap_char_utilities=>newline }Second line{ cl_abap_char_utilities=>newline }Unicode: { unicode_text( `E888AAE7A9BA20F09F9A80` ) }| ).
        lo_editor122->go_to_line( 2 ).
        lo_editor122->set_position( left   = 20
                                    top    = 20
                                    width  = 500
                                    height = 150 ).
      WHEN '123'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT123' ).
        DATA(lo_editor123) = NEW cl_gui_textedit( parent                     = lo_root
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor123->set_textstream( |Readonly Unicode text{ cl_abap_char_utilities=>newline }This cannot be edited| ).
        lo_editor123->set_readonly_mode( cl_gui_textedit=>true ).
        lo_editor123->set_position( left   = 20
                                    top    = 20
                                    width  = 500
                                    height = 120 ).
      WHEN '124'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT124' ).
        DATA(lo_picture124) = NEW cl_gui_picture( parent = lo_root ).
        lo_picture124->load_picture_from_url(
          EXPORTING
            url    = '/assets/icons/refresh.svg'
          IMPORTING
            result = lv_picture_result124 ).
        lo_picture124->set_position( left   = 20
                                     top    = 20
                                     width  = 180
                                     height = 100 ).
      WHEN '125'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT125' ).
        DATA(lo_toolbar125) = NEW cl_gui_toolbar( parent = lo_root ).
        lo_toolbar125->add_button( fcode     = 'RUN'
                                   icon      = '@'
                                   butn_type = 0
                                   text      = 'Run'
                                   quickinfo = 'Run toolbar action' ).
        lo_toolbar125->add_button( fcode       = 'DISABLED'
                                   icon        = '@'
                                   butn_type   = 0
                                   text        = 'Disabled'
                                   quickinfo   = 'Disabled action'
                                   is_disabled = abap_true ).
        lo_toolbar125->set_position( left   = 20
                                     top    = 20
                                     width  = 260
                                     height = 40 ).
      WHEN '126'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT126' ).
        DATA(lo_calendar126) = NEW cl_gui_calendar( parent     = lo_root
                                                    focus_date = '20260830' ).
        lo_calendar126->set_selection( date_begin = '20260830'
                                       date_end   = '20260901' ).
        lo_calendar126->set_position( left   = 20
                                      top    = 20
                                      width  = 360
                                      height = 150 ).
      WHEN '127'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT127' ).
        DATA(lo_selector127) = NEW zcl_gg_selector( parent = lo_root ).
        lo_selector127->set_options( VALUE #(
          ( key = 'AA' text = 'Alpha Airlines' )
          ( key = 'LH' text = 'Lufthansa' )
          ( key = 'UA' text = 'United' ) ) ).
        lo_selector127->set_position( left   = 20
                                      top    = 20
                                      width  = 240
                                      height = 30 ).
      WHEN '128'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT128' ).
        lo_viewer128 = NEW cl_gui_html_viewer( parent = lo_root ).
        lt_html = VALUE #( ( CONV string( '<h2>Sandboxed viewer</h2><p>Escaped viewer content</p>' ) ) ).
        lo_viewer128->load_data( CHANGING data_table = lt_html ).
        lo_viewer128->set_position( left   = 20
                                    top    = 20
                                    width  = 500
                                    height = 150 ).
      WHEN '129'.
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind          = zcl_gg_host_surface=>surface_document
          aria_label    = 'Dynamic document'
          title         = 'Dynamic & safe document'
          text          = 'Escaped text & attributes'
          link_label    = 'Open document'
          link_href     = '/safe/document'
          input_label   = 'Document name'
          input_name    = 'DOCUMENT_NAME'
          input_value   = 'draft'
          table_caption = 'Document rows'
          columns       = VALUE #( ( `Field` ) ( `Value` ) )
          rows          = VALUE #( ( cell1 = 'Status' cell2 = 'Draft' row_header = abap_true ) )
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                   value = 'SAVE_DOC' label = 'Save' ) ) ) ).
      WHEN '130'.
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind       = zcl_gg_host_surface=>surface_event_document
          aria_label = 'Event document'
          title      = 'Typed event dispatch'
          actions    = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                                  value = 'OPEN_DOC' label = 'Open document' ) ) ) ).
      WHEN '131'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT131' ).
        DATA(lo_split131) = NEW cl_gui_splitter_container( parent  = lo_root
                                                           rows    = 1
                                                           columns = 2 ).
        DATA(lo_editor131) = NEW cl_gui_textedit( parent                     = lo_split131
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor131->set_textstream( 'Nested registry editor' ).
        DATA(lo_picture131) = NEW cl_gui_picture( parent = lo_split131 ).
        lo_picture131->load_picture_from_url_async( '/assets/icons/refresh.svg' ).
        DATA(lo_toolbar131) = NEW cl_gui_toolbar( parent = lo_split131 ).
        lo_toolbar131->add_button( fcode     = 'APPLY'
                                   icon      = '@'
                                   butn_type = 0
                                   text      = 'Apply'
                                   quickinfo = 'Apply nested control' ).
      WHEN '132'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT132' ).
        DATA(lo_toolbar132) = NEW cl_gui_toolbar( parent = lo_root ).
        lo_toolbar132->add_button( fcode     = 'REFRESH'
                                   icon      = '@'
                                   butn_type = 0
                                   text      = 'Refresh controls'
                                   quickinfo = 'Refresh server control state' ).
        lo_toolbar132->set_position( left   = 20
                                     top    = 20
                                     width  = 260
                                     height = 40 ).
        write_line( io_session = io_session
                    iv_text    = |control refresh { mv_refresh }| ).
      WHEN '133'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT133' ).
        DATA(lo_editor133) = NEW cl_gui_textedit( parent                     = lo_root
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor133->set_textstream( 'Control with validation' ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind       = zcl_gg_host_surface=>surface_alert
          control_id = lo_editor133->control_id
          text       = 'Editor value is required' ) ).
      WHEN '134'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT134' ).
        DATA(lo_tree134) = NEW cl_gui_simple_tree( parent = lo_root ).
        lt_nodes = VALUE #( ( CONV string( 'Root' ) ) ( CONV string( 'Editor' ) ) ( CONV string( 'Viewer' ) ) ).
        lo_tree134->add_nodes( table_structure_name = 'TREEV_NODE'
                               node_table           = lt_nodes ).
        DATA(lo_editor134) = NEW cl_gui_textedit( parent                     = lo_root
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor134->set_textstream( 'Document editor' ).
        lo_viewer134 = NEW cl_gui_html_viewer( parent = lo_root ).
        lt_html = VALUE #( ( CONV string( '<h2>Document viewer</h2><p>Saved content</p>' ) ) ).
        lo_viewer134->load_data( CHANGING data_table = lt_html ).
    ENDCASE.
  ENDMETHOD.

  METHOD set_status.
    CASE mv_mode.
      WHEN '125'.
        io_session->get_list( )->set_status( VALUE #( status = 'GUI TOOLBAR' active_ucomm = VALUE #( ( 'RUN' ) ) ) ).
      WHEN '129'.
        io_session->get_list( )->set_status( VALUE #( status = 'DOCUMENT' active_ucomm = VALUE #( ( 'SAVE_DOC' ) ) ) ).
      WHEN '130'.
        io_session->get_list( )->set_status( VALUE #( status = 'DOCUMENT EVENTS' active_ucomm = VALUE #( ( 'OPEN_DOC' ) ) ) ).
      WHEN '131'.
        io_session->get_list( )->set_status( VALUE #( status = 'NESTED CONTROLS' active_ucomm = VALUE #( ( 'APPLY' ) ) ) ).
      WHEN '132'.
        io_session->get_list( )->set_status( VALUE #( status = 'CONTROL REFRESH' active_ucomm = VALUE #( ( 'REFRESH' ) ) ) ).
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
    build_controls( io_session ).
    write_line( io_session = io_session
                iv_text    = |GUI control example { mv_mode }| ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    rs_settings = VALUE #(
      title  = |ZCL_GG_EX_{ mv_mode }|
      status = COND #( WHEN mv_mode = '132' THEN 'CONTROL REFRESH' ELSE 'GUI CONTROLS' ) ).
    CASE mv_mode.
      WHEN '125'.
        rs_settings-status = 'GUI TOOLBAR'.
      WHEN '129'.
        rs_settings-status = 'DOCUMENT'.
      WHEN '130'.
        rs_settings-status = 'DOCUMENT EVENTS'.
      WHEN '131'.
        rs_settings-status = 'NESTED CONTROLS'.
      WHEN '132'.
        rs_settings-status = 'CONTROL REFRESH'.
    ENDCASE.
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
      WHEN '125'.
        IF iv_ucomm = 'RUN'.
          write_line( io_session = io_session
                      iv_text    = 'toolbar RUN dispatched by the server' ).
        ENDIF.
      WHEN '129'.
        IF iv_ucomm = 'SAVE_DOC'.
          write_line( io_session = io_session
                      iv_text    = 'document saved by the server' ).
        ENDIF.
      WHEN '130'.
        IF iv_ucomm = 'OPEN_DOC'.
          write_line( io_session = io_session
                      iv_text    = 'event OPEN_DOC dispatched by the server' ).
        ENDIF.
      WHEN '131'.
        IF iv_ucomm = 'APPLY'.
          write_line( io_session = io_session
                      iv_text    = 'nested control action applied by the server' ).
        ENDIF.
      WHEN '132'.
        IF iv_ucomm = 'REFRESH'.
          mv_refresh = mv_refresh + 1.
          build_controls( io_session ).
          write_line( io_session = io_session
                      iv_text    = |control refresh { mv_refresh }| ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
