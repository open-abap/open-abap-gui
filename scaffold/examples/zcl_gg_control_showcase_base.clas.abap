CLASS zcl_gg_control_showcase_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared report implementation for the GUI-control examples 117-134. The
* numbered classes select one snapshot family and publish transaction data.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.
    INTERFACES zif_gg_session_lifecycle_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.
    DATA mv_refresh TYPE i.
    DATA mv_picture_url124 TYPE string.
    DATA mv_picture_mode124 TYPE i.
    DATA mv_picture_async124 TYPE abap_bool.
    DATA mv_picture_border124 TYPE i.
    DATA mv_picture_state124 TYPE string.
    DATA mv_picture_alt124 TYPE string.
    DATA mv_editor_text122 TYPE string.
    DATA mv_editor_saved122 TYPE string.
    DATA mv_cfw_visible132 TYPE abap_bool.
    DATA mv_cfw_enabled132 TYPE abap_bool.
    DATA mv_cfw_events132 TYPE abap_bool.
    DATA mv_cfw_focus132 TYPE abap_bool.
    DATA mv_cfw_timer_running132 TYPE abap_bool.
    DATA mv_cfw_ticks132 TYPE i.
    DATA mv_cfw_width132 TYPE i.
    DATA mv_cfw_height132 TYPE i.
    DATA mo_cfw_timer132 TYPE REF TO cl_gui_timer.
    DATA mv_custom_visible117 TYPE abap_bool.
    DATA mv_custom_width117 TYPE i.
    DATA mv_custom_height117 TYPE i.
    DATA mv_custom_generation117 TYPE i.
    DATA mv_dock_side120 TYPE i.
    DATA mv_dock_extension120 TYPE i.
    DATA mv_dock_visible120 TYPE abap_bool.
    DATA mv_dock_floating120 TYPE abap_bool.
    DATA mv_split_row118 TYPE i.
    DATA mv_split_column118 TYPE i.
    DATA mv_easy_sash119 TYPE i.

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

    METHODS request_value
      IMPORTING
        io_session      TYPE REF TO zif_gg_session_v1
        iv_name         TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS stop_cfw_resources.

    METHODS handle_splitter_command
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_ucomm   TYPE zif_gg_list_processing_types_v1=>ty_ucomm.

    CLASS-METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_control_showcase_base IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
    mv_picture_url124 = '/assets/icons/refresh.svg'.
    mv_picture_alt124 = 'Refresh icon fixture'.
    mv_picture_state124 = 'not-loaded'.
    mv_editor_text122 = |First line{ cl_abap_char_utilities=>newline }Second line{ cl_abap_char_utilities=>newline }Unicode: { unicode_text( `E888AAE7A9BA20F09F9A80` ) }|.
    mv_editor_saved122 = mv_editor_text122.
    mv_cfw_visible132 = abap_true.
    mv_cfw_enabled132 = abap_true.
    mv_cfw_events132 = abap_true.
    mv_cfw_width132 = 420.
    mv_cfw_height132 = 220.
    mv_custom_visible117 = abap_true.
    mv_custom_width117 = 360.
    mv_custom_height117 = 80.
    mv_custom_generation117 = 1.
    mv_dock_side120 = cl_gui_docking_container=>dock_at_left.
    mv_dock_extension120 = 180.
    mv_dock_visible120 = abap_true.
    mv_split_row118 = 45.
    mv_split_column118 = 60.
    mv_easy_sash119 = 40.
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

  METHOD build_controls.
    DATA lo_root TYPE REF TO cl_gui_custom_container.
    DATA lt_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_nodes TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lo_viewer128 TYPE REF TO cl_gui_html_viewer.
    DATA lo_viewer134 TYPE REF TO cl_gui_html_viewer.
    DATA lv_picture_result124 TYPE i.
    DATA lo_link129 TYPE REF TO cl_dd_link_element.
    DATA lo_form129 TYPE REF TO cl_dd_form_area.
    DATA lo_input129 TYPE REF TO cl_dd_input_element.
    DATA lo_select129 TYPE REF TO cl_dd_select_element.
    DATA lo_button129 TYPE REF TO cl_dd_button_element.
    DATA lo_table129 TYPE REF TO cl_dd_table_element.
    DATA lo_tablearea129 TYPE REF TO cl_dd_table_area.
    DATA lv_main_url129 TYPE string.
    DATA lv_offline_info129 TYPE string.
    DATA lv_document_position129 TYPE i.
    DATA lt_cfw_events132 TYPE cntl_simple_events.
    DATA ls_cfw_surface132 TYPE zcl_gg_host_surface=>ty_surface.
    DATA ls_custom_surface117 TYPE zcl_gg_host_surface=>ty_surface.
    DATA ls_dock_surface120 TYPE zcl_gg_host_surface=>ty_surface.
    DATA ls_split_surface118 TYPE zcl_gg_host_surface=>ty_surface.
    DATA ls_easy_surface119 TYPE zcl_gg_host_surface=>ty_surface.

    CASE mv_mode.
      WHEN '117'.
        lo_root = NEW cl_gui_custom_container(
          container_name          = 'ROOT117'
          repid                   = 'ZCL_GG_EX_117'
          dynnr                   = '0100'
          no_autodef_progid_dynnr = abap_true
          lifetime                = cl_gui_control=>lifetime_dynpro ).
        DATA(lo_editor117) = NEW cl_gui_textedit( parent                     = lo_root
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor117->set_textstream( |Child control in custom container (generation { mv_custom_generation117 })| ).
        lo_editor117->set_visible( mv_custom_visible117 ).
        lo_editor117->set_position( left   = 20
                                    top    = 30
                                    width  = mv_custom_width117
                                    height = mv_custom_height117 ).
        ls_custom_surface117 = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Custom container diagnostics'
          table_caption = 'Named custom-control lifecycle'
          columns       = VALUE #( ( `Property` ) ( `Value` ) ( `Scope` ) )
          rows          = VALUE #(
            ( cell1 = 'Container name' cell2 = 'ROOT117' cell3 = 'named host area' )
            ( cell1 = 'Dynpro area' cell2 = 'ZCL_GG_EX_117 / 0100' cell3 = 'explicit identity' )
            ( cell1 = 'Parent' cell2 = 'list work area' cell3 = 'host session' )
            ( cell1 = 'Child identity' cell2 = |TEXTEDIT generation { mv_custom_generation117 }| cell3 = 'attached child' )
            ( cell1 = 'Visible' cell2 = COND string( WHEN mv_custom_visible117 = abap_true THEN 'yes' ELSE 'no' ) cell3 = 'child state' )
            ( cell1 = 'Geometry' cell2 = |{ mv_custom_width117 } x { mv_custom_height117 }| cell3 = 'child pixels' ) )
          text          = 'The browser keeps the named container, child identity, visibility, geometry, and lifecycle state observable.'
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RESIZE_CHILD' label = 'Resize child' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'TOGGLE_CHILD' label = 'Toggle child' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RECREATE_CHILD' label = 'Recreate child' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RESET_CONTAINER' label = 'Reset container' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_custom_surface117 ).
      WHEN '118'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT118' ).
        DATA(lo_split118) = NEW cl_gui_splitter_container( parent  = lo_root
                                                           rows    = 2
                                                           columns = 1 ).
        lo_split118->set_position( left   = 10
                                   top    = 10
                                   width  = 500
                                   height = 240 ).
        lo_split118->set_row_height(
          EXPORTING
            id     = 1
            height = mv_split_row118
          IMPORTING
            result = DATA(lv_split_row_result118) ).
        lo_split118->set_row_minimum(
          EXPORTING
            id      = 1
            minimum = 30
          IMPORTING
            result  = DATA(lv_split_min_result118) ).
        DATA(lo_outer_first118) = lo_split118->get_container(
          row    = 1
          column = 1 ).
        DATA(lo_outer_second118) = lo_split118->get_container(
          row    = 2
          column = 1 ).
        DATA(lo_editor118a) = NEW cl_gui_textedit( parent                     = lo_outer_first118
                                                   wordwrap_to_linebreak_mode = 0 ).
        lo_editor118a->set_textstream( 'Outer editor pane' ).
        DATA(lo_nested118) = NEW cl_gui_splitter_container( parent  = lo_outer_second118
                                                            rows    = 1
                                                            columns = 2 ).
        lo_nested118->set_column_width(
          EXPORTING
            id     = 1
            width  = mv_split_column118
          IMPORTING
            result = DATA(lv_split_column_result118) ).
        DATA(lo_nested_left118) = lo_nested118->get_container(
          row    = 1
          column = 1 ).
        DATA(lo_nested_right118) = lo_nested118->get_container(
          row    = 1
          column = 2 ).
        DATA(lo_editor118b) = NEW cl_gui_textedit( parent                     = lo_nested_left118
                                                   wordwrap_to_linebreak_mode = 0 ).
        lo_editor118b->set_textstream( 'Nested editor pane' ).
        DATA(lo_viewer118) = NEW cl_gui_html_viewer( parent = lo_nested_right118 ).
        lt_html = VALUE #( ( CONV string( '<h3>HTML viewer pane</h3><p>Nested splitter content remains readable.</p>' ) ) ).
        lo_viewer118->load_data( CHANGING data_table = lt_html ).
        ls_split_surface118 = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Nested splitter diagnostics'
          table_caption = 'Nested splitter grid'
          columns       = VALUE #( ( `Property` ) ( `Value` ) ( `State` ) )
          rows          = VALUE #(
            ( cell1 = 'Outer grid' cell2 = '2 rows x 1 column' cell3 = 'retained' )
            ( cell1 = 'Inner grid' cell2 = '1 row x 2 columns' cell3 = 'nested' )
            ( cell1 = 'Row sash' cell2 = |{ mv_split_row118 } px| cell3 = 'movable' )
            ( cell1 = 'Column sash' cell2 = |{ mv_split_column118 } px| cell3 = 'movable' )
            ( cell1 = 'Minimum size' cell2 = '30 px' cell3 = 'enforced' )
            ( cell1 = 'Viewer pane' cell2 = 'HTML document' cell3 = 'accessible' ) )
          text          = 'Nested editor and HTML viewer panes retain their sash positions and minimum sizes across actions.'
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'MOVE_ROW_SASH' label = 'Move row sash' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'MOVE_COLUMN_SASH' label = 'Move column sash' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RESET_SPLITTER' label = 'Reset splitter' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_split_surface118 ).
      WHEN '119'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT119' ).
        DATA(lo_easy119) = NEW cl_gui_easy_splitter_container( parent        = lo_root
                                                               orientation   = cl_gui_easy_splitter_container=>orientation_horizontal
                                                               sash_position = mv_easy_sash119 ).
        lo_easy119->set_minimum_size( 24 ).
        lo_easy119->set_position( left   = 10
                                  top    = 10
                                  width  = 500
                                  height = 180 ).
        lo_easy119->set_sash_position( mv_easy_sash119 ).
        DATA(lo_editor119) = NEW cl_gui_textedit( parent                     = lo_easy119->top_left_container
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor119->set_textstream( 'Easy splitter content' ).
        DATA(lo_viewer119) = NEW cl_gui_html_viewer( parent = lo_easy119->bottom_right_container ).
        lt_html = VALUE #( ( CONV string( '<h3>Easy splitter viewer</h3><p>The second pane is HTML content.</p>' ) ) ).
        lo_viewer119->load_data( CHANGING data_table = lt_html ).
        ls_easy_surface119 = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Easy splitter diagnostics'
          table_caption = 'Easy splitter state'
          columns       = VALUE #( ( `Property` ) ( `Value` ) ( `State` ) )
          rows          = VALUE #( ( cell1 = 'Orientation' cell2 = 'horizontal' cell3 = 'retained' )
                          ( cell1 = 'Sash position' cell2 = |{ mv_easy_sash119 } %| cell3 = 'movable' )
                          ( cell1 = 'Minimum pane size' cell2 = '24 px' cell3 = 'enforced' )
                          ( cell1 = 'Panes' cell2 = 'editor + HTML viewer' cell3 = 'nested containers' ) )
          text          = 'The easy splitter keeps both panes available and exposes a bounded server-owned sash percentage.'
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'MOVE_EASY_SASH' label = 'Move sash' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RESET_EASY_SPLITTER' label = 'Reset splitter' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_easy_surface119 ).
      WHEN '120'.
        lo_root = NEW cl_gui_custom_container( container_name = 'ROOT120' ).
        DATA(lo_dock120) = NEW cl_gui_docking_container( parent    = lo_root
                                                         side      = mv_dock_side120
                                                         extension = mv_dock_extension120
                                                         caption   = 'Docked tools' ).
        lo_dock120->float( COND i( WHEN mv_dock_floating120 = abap_true THEN 1 ELSE 0 ) ).
        lo_dock120->set_visible( mv_dock_visible120 ).
        lo_dock120->set_position( left   = 330
                                  top    = 10
                                  width  = mv_dock_extension120
                                  height = 160 ).
        DATA(lo_editor120) = NEW cl_gui_textedit( parent                     = lo_dock120
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor120->set_textstream( 'Docked content' ).
        ls_dock_surface120 = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Docking container diagnostics'
          table_caption = 'Main diagnostic area'
          columns       = VALUE #( ( `Property` ) ( `Value` ) ( `State` ) )
          rows          = VALUE #(
            ( cell1 = 'Dock side' cell2 = COND string( WHEN mv_dock_side120 = cl_gui_docking_container=>dock_at_left THEN 'left' ELSE 'right' ) cell3 = 'server-owned' )
            ( cell1 = 'Extension' cell2 = |{ mv_dock_extension120 } px| cell3 = 'resizable' )
            ( cell1 = 'Visible' cell2 = COND string( WHEN mv_dock_visible120 = abap_true THEN 'yes' ELSE 'no' ) cell3 = 'dock state' )
            ( cell1 = 'Floating' cell2 = COND string( WHEN mv_dock_floating120 = abap_true THEN 'yes' ELSE 'no' ) cell3 = 'side preserved' ) )
          text          = 'The main diagnostic area remains available while the left dock is resized, hidden, or floated.'
          actions       = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'EXTEND_DOCK' label = 'Extend dock' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'TOGGLE_DOCK' label = 'Toggle dock' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'FLOAT_DOCK' label = 'Float dock' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'DOCK_RIGHT' label = 'Dock right' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'RESET_DOCK' label = 'Reset dock' ) ) ).
        zcl_gg_host_surface=>set_surface( ls_dock_surface120 ).
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
        lo_editor122->set_textstream( mv_editor_text122 ).
        lo_editor122->go_to_line( 2 ).
        lo_editor122->set_toolbar_mode( cl_gui_textedit=>true ).
        lo_editor122->set_statusbar_mode( cl_gui_textedit=>true ).
        lo_editor122->set_font_fixed( cl_gui_textedit=>true ).
        lo_editor122->set_wordwrap_behavior(
          wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
          wordwrap_position          = 72
          wordwrap_to_linebreak_mode = 0 ).
        lo_editor122->protect_lines( from_line = 1
                                     to_line   = 1 ).
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
        lo_picture124->set_display_mode( mv_picture_mode124 ).
        lo_picture124->set_3d_border( mv_picture_border124 ).
        lo_picture124->set_alt_text( mv_picture_alt124 ).
        IF mv_picture_url124 IS INITIAL.
          mv_picture_state124 = 'empty'.
        ELSEIF mv_picture_async124 = abap_true.
          lo_picture124->load_picture_from_url_async( mv_picture_url124 ).
          mv_picture_state124 = COND #( WHEN mv_picture_url124 CP '/assets/*' THEN 'loaded' ELSE 'rejected' ).
        ELSE.
          lo_picture124->load_picture_from_url(
            EXPORTING
              url    = mv_picture_url124
            IMPORTING
              result = lv_picture_result124 ).
          mv_picture_state124 = COND #( WHEN lv_picture_result124 = 0 THEN 'loaded' ELSE 'rejected' ).
        ENDIF.
        lo_picture124->set_position( left   = 20
                                     top    = 20
                                     width  = 180
                                     height = 100 ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind        = zcl_gg_host_surface=>surface_document
          aria_label  = 'Picture control state'
          title       = 'Picture URL and display state'
          text        = |State: { mv_picture_state124 }; mode: { mv_picture_mode124 }; async: { COND string( WHEN mv_picture_async124 = abap_true THEN 'yes' ELSE 'no' ) }. Only /assets fixtures are loadable.|
          input_label = 'Picture URL'
          input_name  = 'PICTURE_URL'
          input_value = mv_picture_url124
          rows        = VALUE #( ( cell1 = 'State' cell2 = mv_picture_state124 )
                                  ( cell1 = 'Alternative text' cell2 = mv_picture_alt124 )
                                  ( cell1 = 'Border' cell2 = |{ mv_picture_border124 }| ) )
          columns     = VALUE #( ( `Property` ) ( `Value` ) )
          actions     = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PICTURE_LOAD' label = 'Load URL' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PICTURE_ASYNC' label = 'Toggle async' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PICTURE_FIT' label = 'Fit and center' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PICTURE_NORMAL' label = 'Normal size' )
                                   ( transport = zcl_gg_host_surface=>surface_action_ucomm value = 'PICTURE_CLEAR' label = 'Clear' ) ) ) ).
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
        lo_toolbar125->add_button( fcode      = 'TOGGLE'
                                   icon       = '@'
                                   butn_type  = 1
                                   text       = 'Toggle'
                                   quickinfo  = 'Toggle state'
                                   is_checked = 'X' ).
        lo_toolbar125->add_button( fcode     = 'MENU'
                                   icon      = '@'
                                   butn_type = 3
                                   text      = 'Menu'
                                   quickinfo = 'Open toolbar menu' ).
        lo_toolbar125->add_button( fcode     = 'SEPARATOR'
                                   icon      = '@'
                                   butn_type = 2
                                   text      = ''
                                   quickinfo = 'Separator' ).
        lo_toolbar125->add_button( fcode     = 'DROPDOWN'
                                   icon      = '@'
                                   butn_type = 4
                                   text      = 'Dropdown'
                                   quickinfo = 'Open dropdown' ).
        lo_toolbar125->add_button( fcode     = 'ACTION1'
                                   icon      = '@'
                                   butn_type = 0
                                   text      = 'Action 1'
                                   quickinfo = 'Additional action 1' ).
        lo_toolbar125->add_button( fcode     = 'ACTION2'
                                   icon      = '@'
                                   butn_type = 0
                                   text      = 'Action 2'
                                   quickinfo = 'Additional action 2' ).
        DATA(lo_menu125) = NEW cl_ctmenu( ).
        lo_menu125->add_function( fcode = 'MENU_ACTION'
                                  text  = 'Menu action' ).
        lo_menu125->add_separator( ).
        lo_menu125->add_function( fcode    = 'MENU_DISABLED'
                                  text     = 'Disabled menu item'
                                  disabled = abap_true ).
        lo_toolbar125->set_static_ctxmenu( fcode   = 'MENU'
                                           ctxmenu = lo_menu125
                                           btntype = 3 ).
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
        DATA(lo_document129) = NEW cl_dd_document( background_color = 35 ).
        lo_document129->add_text(
          text         = 'Dynamic & safe document'
          sap_style    = cl_dd_area=>heading
          a11y_tooltip = 'Document heading' ).
        lo_document129->new_line( ).
        lo_document129->add_text(
          text         = 'Escaped text & attributes'
          a11y_tooltip = 'Document body' ).
        lo_document129->add_gap( width = 8 ).
        lo_document129->add_icon(
          sap_icon         = 'DOC'
          alternative_text = 'Document icon' ).
        lo_document129->add_link(
          EXPORTING
            url     = '/safe/document'
            text    = 'Open document'
            name    = 'SAFE_DOCUMENT'
            tooltip = 'Open the safe document'
          IMPORTING
            link    = lo_link129 ).
        lo_document129->add_form(
          IMPORTING
            formarea         = lo_form129
            main_url         = lv_main_url129
            alv_offline_info = lv_offline_info129 ).
        lo_form129->add_input_element(
          EXPORTING
            value         = 'draft'
            name          = 'DOCUMENT_NAME'
            size          = 18
            maxlength     = 40
            tooltip       = 'Document name'
            a11y_label    = 'Document name'
          IMPORTING
            input_element = lo_input129 ).
        lo_form129->add_select_element(
          EXPORTING
            name           = 'DOCUMENT_KIND'
            value          = 'REPORT'
            options        = VALUE #( ( value = 'REPORT' text = 'Report' )
                                     ( value = 'NOTE' text = 'Note' ) )
            tooltip        = 'Document kind'
            a11y_label     = 'Document kind'
          IMPORTING
            select_element = lo_select129 ).
        lo_form129->add_button(
          EXPORTING
            label   = 'Save'
            name    = 'SAVE_DOC'
            tooltip = 'Save document'
          IMPORTING
            button  = lo_button129 ).
        lo_document129->add_table(
          EXPORTING
            no_of_columns = 2
            with_heading  = abap_true
            a11y_label    = 'Document rows'
          IMPORTING
            table         = lo_table129
            tablearea     = lo_tablearea129 ).
        lo_tablearea129->new_row( ).
        lo_tablearea129->add_heading( 'Field' ).
        lo_tablearea129->add_heading( 'Value' ).
        lo_document129->html_insert(
          EXPORTING
            contents = '<td>Status</td><td>Draft</td></tr></tbody></table></form>'
          CHANGING
            position = lv_document_position129 ).
        lo_document129->merge_document( ).
        zcl_gg_host_surface=>set_surface( VALUE #(
          kind         = zcl_gg_host_surface=>surface_document
          aria_label   = 'Dynamic document'
          title        = 'Dynamic & safe document'
          text         = 'Escaped text & attributes'
          html_content = lo_document129->html_content
          actions      = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
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
        DATA(lo_editor132) = NEW cl_gui_textedit( parent                     = lo_root
                                                  wordwrap_to_linebreak_mode = 0 ).
        lo_editor132->set_textstream( 'Control Framework lifecycle sample' ).
        lo_editor132->set_toolbar_mode( 1 ).
        lo_editor132->set_statusbar_mode( 1 ).
        lo_editor132->set_visible( mv_cfw_visible132 ).
        lo_editor132->set_enable( mv_cfw_enabled132 ).
        lo_editor132->set_position( left   = 8
                                    top    = 8
                                    width  = mv_cfw_width132
                                    height = mv_cfw_height132 ).
        lt_cfw_events132 = VALUE #( ( eventid    = cl_gui_textedit=>event_double_click
                                      appl_event = mv_cfw_events132 ) ).
        lo_editor132->set_registered_events( lt_cfw_events132 ).
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
        IF mo_cfw_timer132 IS NOT BOUND.
          mo_cfw_timer132 = NEW cl_gui_timer( ).
        ENDIF.
        mo_cfw_timer132->interval = 1000.
        cl_gui_control=>initialize( control = mo_cfw_timer132
                                    parent  = lo_root
                                    kind    = 'TIMER' ).
        lo_root->add_child( mo_cfw_timer132 ).
        IF mv_cfw_timer_running132 = abap_true.
          mo_cfw_timer132->run( ).
        ENDIF.
        IF mv_cfw_focus132 = abap_true.
          cl_gui_control=>set_focus( lo_editor132 ).
        ENDIF.
        ls_cfw_surface132 = VALUE #(
          kind          = zcl_gg_host_surface=>surface_table
          aria_label    = 'Control Framework lifecycle'
          table_caption = 'Control Framework state'
          columns       = VALUE #( ( `Property` ) ( `Value` ) ( `Scope` ) )
          rows          = VALUE #(
            ( cell1 = 'Visible' cell2 = COND string( WHEN mv_cfw_visible132 = abap_true THEN 'yes' ELSE 'no' ) cell3 = 'editor' )
            ( cell1 = 'Enabled' cell2 = COND string( WHEN mv_cfw_enabled132 = abap_true THEN 'yes' ELSE 'no' ) cell3 = 'editor' )
            ( cell1 = 'Application event' cell2 = COND string( WHEN mv_cfw_events132 = abap_true THEN 'on' ELSE 'off' ) cell3 = 'double-click' )
            ( cell1 = 'Timer ticks' cell2 = |{ mv_cfw_ticks132 }| cell3 = 'session clock' )
            ( cell1 = 'Geometry' cell2 = |{ mv_cfw_width132 } x { mv_cfw_height132 }| cell3 = 'editor pixels' ) )
          text          = 'Control state, event registration, timer ticks, and geometry are kept in one server-owned lifecycle.' ).
        zcl_gg_host_surface=>set_surface( ls_cfw_surface132 ).
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

  METHOD handle_splitter_command.
    cl_gui_control=>clear( ).
    zcl_gg_host_surface=>clear( ).
    CASE mv_mode.
      WHEN '118'.
        CASE iv_ucomm.
          WHEN 'MOVE_ROW_SASH'.
            mv_split_row118 = COND #( WHEN mv_split_row118 = 45 THEN 70 ELSE 45 ).
            write_line( io_session = io_session
                        iv_text    = |Outer row sash moved to { mv_split_row118 } px| ).
          WHEN 'MOVE_COLUMN_SASH'.
            mv_split_column118 = COND #( WHEN mv_split_column118 = 60 THEN 72 ELSE 60 ).
            write_line( io_session = io_session
                        iv_text    = |Inner column sash moved to { mv_split_column118 } px| ).
          WHEN 'RESET_SPLITTER'.
            mv_split_row118 = 45.
            mv_split_column118 = 60.
            write_line( io_session = io_session
                        iv_text    = 'Nested splitter ratios and minimum sizes restored' ).
        ENDCASE.
      WHEN '119'.
        CASE iv_ucomm.
          WHEN 'MOVE_EASY_SASH'.
            mv_easy_sash119 = COND #( WHEN mv_easy_sash119 = 40 THEN 65 ELSE 40 ).
            write_line( io_session = io_session
                        iv_text    = |Easy splitter sash moved to { mv_easy_sash119 } percent| ).
          WHEN 'RESET_EASY_SPLITTER'.
            mv_easy_sash119 = 40.
            write_line( io_session = io_session
                        iv_text    = 'Easy splitter sash and minimum pane size restored' ).
        ENDCASE.
    ENDCASE.
    build_controls( io_session ).
    set_status( io_session ).
  ENDMETHOD.

  METHOD set_status.
    CASE mv_mode.
      WHEN '117'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'CUSTOM CONTAINER'
          active_ucomm = VALUE #( ( 'RESIZE_CHILD' ) ( 'TOGGLE_CHILD' ) ( 'RECREATE_CHILD' ) ( 'RESET_CONTAINER' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'RESIZE_CHILD' label = 'Resize child' icon = 'expand' )
            ( ucomm = 'TOGGLE_CHILD' label = 'Toggle child' icon = 'display' )
            ( ucomm = 'RECREATE_CHILD' label = 'Recreate child' icon = 'refresh' )
            ( ucomm = 'RESET_CONTAINER' label = 'Reset container' icon = 'undo' ) ) ) ).
      WHEN '118'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'SPLITTER CONTAINER'
          active_ucomm = VALUE #( ( 'MOVE_ROW_SASH' ) ( 'MOVE_COLUMN_SASH' ) ( 'RESET_SPLITTER' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'MOVE_ROW_SASH' label = 'Move row sash' icon = 'arrow-down' )
            ( ucomm = 'MOVE_COLUMN_SASH' label = 'Move column sash' icon = 'arrow-right' )
            ( ucomm = 'RESET_SPLITTER' label = 'Reset splitter' icon = 'undo' ) ) ) ).
      WHEN '119'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'EASY SPLITTER'
          active_ucomm = VALUE #( ( 'MOVE_EASY_SASH' ) ( 'RESET_EASY_SPLITTER' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'MOVE_EASY_SASH' label = 'Move sash' icon = 'arrow-right' )
            ( ucomm = 'RESET_EASY_SPLITTER' label = 'Reset splitter' icon = 'undo' ) ) ) ).
      WHEN '120'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'DOCKING CONTAINER'
          active_ucomm = VALUE #( ( 'EXTEND_DOCK' ) ( 'TOGGLE_DOCK' ) ( 'FLOAT_DOCK' ) ( 'DOCK_RIGHT' ) ( 'RESET_DOCK' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'EXTEND_DOCK' label = 'Extend dock' icon = 'expand' )
            ( ucomm = 'TOGGLE_DOCK' label = 'Toggle dock' icon = 'display' )
            ( ucomm = 'FLOAT_DOCK' label = 'Float dock' icon = 'window' )
            ( ucomm = 'DOCK_RIGHT' label = 'Dock right' icon = 'arrow-right' )
            ( ucomm = 'RESET_DOCK' label = 'Reset dock' icon = 'undo' ) ) ) ).
      WHEN '122'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'TEXT EDITOR'
          active_ucomm = VALUE #( ( 'TEXT_CLEAR' ) ( 'TEXT_RESTORE' ) ( 'TEXT_LOAD_FILE' ) ( 'TEXT_SAVE_FILE' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'TEXT_CLEAR' label = 'Clear text' icon = 'delete' )
            ( ucomm = 'TEXT_RESTORE' label = 'Restore text' icon = 'undo' )
            ( ucomm = 'TEXT_LOAD_FILE' label = 'Load file' icon = 'upload' )
            ( ucomm = 'TEXT_SAVE_FILE' label = 'Save file' icon = 'download' ) ) ) ).
      WHEN '124'.
        io_session->get_list( )->set_status( VALUE #(
          status       = COND string( WHEN mv_picture_state124 = 'rejected' THEN 'PICTURE REJECTED' ELSE 'PICTURE READY' )
          active_ucomm = VALUE #( ( 'PICTURE_LOAD' ) ( 'PICTURE_ASYNC' ) ( 'PICTURE_FIT' )
                                  ( 'PICTURE_NORMAL' ) ( 'PICTURE_CLEAR' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'PICTURE_LOAD' label = 'Load image' icon = 'upload' )
            ( ucomm = 'PICTURE_ASYNC' label = 'Async load' icon = 'refresh' )
            ( ucomm = 'PICTURE_FIT' label = 'Fit and center' icon = 'expand' )
            ( ucomm = 'PICTURE_NORMAL' label = 'Normal size' icon = 'display' )
            ( ucomm = 'PICTURE_CLEAR' label = 'Clear image' icon = 'delete' ) ) ) ).
      WHEN '125'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'GUI TOOLBAR'
          active_ucomm = VALUE #( ( 'RUN' ) ( 'TOGGLE' ) ( 'MENU' ) ( 'DROPDOWN' ) ( 'ACTION1' ) ( 'ACTION2' ) ( 'MENU_ACTION' ) ) ) ).
      WHEN '129'.
        io_session->get_list( )->set_status( VALUE #( status = 'DOCUMENT' active_ucomm = VALUE #( ( 'SAVE_DOC' ) ) ) ).
      WHEN '130'.
        io_session->get_list( )->set_status( VALUE #( status = 'DOCUMENT EVENTS' active_ucomm = VALUE #( ( 'OPEN_DOC' ) ) ) ).
      WHEN '131'.
        io_session->get_list( )->set_status( VALUE #( status = 'NESTED CONTROLS' active_ucomm = VALUE #( ( 'APPLY' ) ) ) ).
      WHEN '132'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'CONTROL FRAMEWORK'
          active_ucomm = VALUE #( ( 'FOCUS' ) ( 'VISIBLE' ) ( 'ENABLE' ) ( 'EVENT' ) ( 'RESIZE' )
                                  ( 'RUN_TIMER' ) ( 'TICK_TIMER' ) ( 'REFRESH' ) ( 'RESET' ) )
          icon_bar     = VALUE #(
            ( ucomm = 'FOCUS' label = 'Focus editor' icon = 'focus' )
            ( ucomm = 'VISIBLE' label = 'Toggle visibility' icon = 'display' )
            ( ucomm = 'ENABLE' label = 'Toggle enablement' icon = 'check' )
            ( ucomm = 'EVENT' label = 'Toggle event' icon = 'event' )
            ( ucomm = 'RESIZE' label = 'Resize editor' icon = 'expand' )
            ( ucomm = 'RUN_TIMER' label = 'Run timer' icon = 'play' )
            ( ucomm = 'TICK_TIMER' label = 'Tick timer' icon = 'refresh' )
            ( ucomm = 'REFRESH' label = 'Refresh controls' icon = 'refresh' )
            ( ucomm = 'RESET' label = 'Reset controls' icon = 'undo' ) ) ) ).
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
      status = COND #( WHEN mv_mode = '132' THEN 'CONTROL FRAMEWORK' ELSE 'GUI CONTROLS' ) ).
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
        rs_settings-status = 'CONTROL FRAMEWORK'.
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
      WHEN '117'.
        cl_gui_control=>clear( ).
        zcl_gg_host_surface=>clear( ).
        CASE iv_ucomm.
          WHEN 'RESIZE_CHILD'.
            IF mv_custom_width117 = 360.
              mv_custom_width117 = 520.
              mv_custom_height117 = 120.
            ELSE.
              mv_custom_width117 = 360.
              mv_custom_height117 = 80.
            ENDIF.
            write_line( io_session = io_session
                        iv_text    = |Custom child resized to { mv_custom_width117 } x { mv_custom_height117 }| ).
          WHEN 'TOGGLE_CHILD'.
            mv_custom_visible117 = xsdbool( mv_custom_visible117 = abap_false ).
            write_line( io_session = io_session
                        iv_text    = |Custom child visible: { COND string( WHEN mv_custom_visible117 = abap_true THEN 'yes' ELSE 'no' ) }| ).
          WHEN 'RECREATE_CHILD'.
            mv_custom_generation117 = mv_custom_generation117 + 1.
            write_line( io_session = io_session
                        iv_text    = |Named custom child recreated; generation { mv_custom_generation117 }| ).
          WHEN 'RESET_CONTAINER'.
            mv_custom_visible117 = abap_true.
            mv_custom_width117 = 360.
            mv_custom_height117 = 80.
            mv_custom_generation117 = 1.
            write_line( io_session = io_session
                        iv_text    = 'Initial named custom-container state restored' ).
        ENDCASE.
        build_controls( io_session ).
        set_status( io_session ).
      WHEN '118' OR '119'.
        handle_splitter_command( io_session = io_session
                                 iv_ucomm   = iv_ucomm ).
      WHEN '120'.
        cl_gui_control=>clear( ).
        zcl_gg_host_surface=>clear( ).
        CASE iv_ucomm.
          WHEN 'EXTEND_DOCK'.
            IF mv_dock_extension120 = 180.
              mv_dock_extension120 = 260.
            ELSE.
              mv_dock_extension120 = 180.
            ENDIF.
            write_line( io_session = io_session
                        iv_text    = |Dock extension changed to { mv_dock_extension120 } px| ).
          WHEN 'TOGGLE_DOCK'.
            mv_dock_visible120 = xsdbool( mv_dock_visible120 = abap_false ).
            write_line( io_session = io_session
                        iv_text    = |Dock visible: { COND string( WHEN mv_dock_visible120 = abap_true THEN 'yes' ELSE 'no' ) }| ).
          WHEN 'FLOAT_DOCK'.
            mv_dock_floating120 = xsdbool( mv_dock_floating120 = abap_false ).
            write_line( io_session = io_session
                        iv_text    = |Dock floating: { COND string( WHEN mv_dock_floating120 = abap_true THEN 'yes' ELSE 'no' ) }| ).
          WHEN 'DOCK_RIGHT'.
            mv_dock_side120 = cl_gui_docking_container=>dock_at_right.
            write_line( io_session = io_session
                        iv_text    = 'Dock moved to the right; extension and visibility were retained' ).
          WHEN 'RESET_DOCK'.
            mv_dock_side120 = cl_gui_docking_container=>dock_at_left.
            mv_dock_extension120 = 180.
            mv_dock_visible120 = abap_true.
            mv_split_row118 = 45.
            mv_split_column118 = 60.
            mv_easy_sash119 = 40.
            mv_dock_floating120 = abap_false.
            write_line( io_session = io_session
                        iv_text    = 'Initial left docking state restored' ).
        ENDCASE.
        build_controls( io_session ).
        set_status( io_session ).
      WHEN '122'.
        cl_gui_control=>clear( ).
        CASE iv_ucomm.
          WHEN 'TEXT_CLEAR'.
            mv_editor_saved122 = mv_editor_text122.
            CLEAR mv_editor_text122.
            write_line( io_session = io_session
                        iv_text    = 'Text editor cleared; the previous stream can be restored' ).
          WHEN 'TEXT_RESTORE'.
            mv_editor_text122 = mv_editor_saved122.
            write_line( io_session = io_session
                        iv_text    = 'Text editor restored from server-owned stream state' ).
          WHEN 'TEXT_LOAD_FILE' OR 'TEXT_SAVE_FILE'.
            write_line( io_session = io_session
                        iv_text    = 'Desktop file access is unavailable; text editor remains usable in the browser' ).
        ENDCASE.
        build_controls( io_session ).
        set_status( io_session ).
      WHEN '124'.
        cl_gui_control=>clear( ).
        zcl_gg_host_surface=>clear( ).
        CASE iv_ucomm.
          WHEN 'PICTURE_LOAD'.
            DATA(lv_picture_url) = request_value( io_session = io_session
                                                  iv_name    = 'PICTURE_URL' ).
            IF lv_picture_url IS NOT INITIAL.
              mv_picture_url124 = lv_picture_url.
            ENDIF.
            mv_picture_async124 = abap_false.
            write_line( io_session = io_session
                        iv_text    = |Picture load requested for { mv_picture_url124 }| ).
          WHEN 'PICTURE_ASYNC'.
            mv_picture_async124 = xsdbool( mv_picture_async124 = abap_false ).
            write_line( io_session = io_session
                        iv_text    = |Picture async mode { COND string( WHEN mv_picture_async124 = abap_true THEN 'enabled' ELSE 'disabled' ) }| ).
          WHEN 'PICTURE_FIT'.
            mv_picture_mode124 = cl_gui_picture=>display_mode_fit_center.
            mv_picture_border124 = 1.
            write_line( io_session = io_session
                        iv_text    = 'Picture fit and center mode enabled' ).
          WHEN 'PICTURE_NORMAL'.
            mv_picture_mode124 = cl_gui_picture=>display_mode_normal.
            write_line( io_session = io_session
                        iv_text    = 'Picture normal-size mode enabled' ).
          WHEN 'PICTURE_CLEAR'.
            CLEAR mv_picture_url124.
            mv_picture_state124 = 'empty'.
            write_line( io_session = io_session
                        iv_text    = 'Picture cleared' ).
        ENDCASE.
        build_controls( io_session ).
        set_status( io_session ).
      WHEN '125'.
        CASE iv_ucomm.
          WHEN 'RUN'.
            write_line( io_session = io_session
                        iv_text    = 'toolbar RUN dispatched by the server' ).
          WHEN 'TOGGLE'.
            write_line( io_session = io_session
                        iv_text    = 'toolbar toggle state dispatched by the server' ).
          WHEN 'MENU' OR 'DROPDOWN'.
            write_line( io_session = io_session
                        iv_text    = |toolbar { iv_ucomm } dispatched by the server| ).
          WHEN 'MENU_ACTION'.
            write_line( io_session = io_session
                        iv_text    = 'toolbar menu action dispatched by the server' ).
          WHEN 'ACTION1' OR 'ACTION2'.
            write_line( io_session = io_session
                        iv_text    = |toolbar { iv_ucomm } dispatched by the server| ).
        ENDCASE.
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
        cl_gui_control=>clear( ).
        zcl_gg_host_surface=>clear( ).
        CASE iv_ucomm.
          WHEN 'FOCUS'.
            mv_cfw_focus132 = abap_true.
            write_line( io_session = io_session
                        iv_text    = 'Editor focus set and returned by the control framework' ).
          WHEN 'VISIBLE'.
            mv_cfw_visible132 = xsdbool( mv_cfw_visible132 = abap_false ).
            write_line( io_session = io_session
                        iv_text    = |Editor visible state: { COND string( WHEN mv_cfw_visible132 = abap_true THEN 'yes' ELSE 'no' ) }| ).
          WHEN 'ENABLE'.
            mv_cfw_enabled132 = xsdbool( mv_cfw_enabled132 = abap_false ).
            write_line( io_session = io_session
                        iv_text    = |Editor enabled state: { COND string( WHEN mv_cfw_enabled132 = abap_true THEN 'yes' ELSE 'no' ) }| ).
          WHEN 'EVENT'.
            mv_cfw_events132 = xsdbool( mv_cfw_events132 = abap_false ).
            write_line( io_session = io_session
                        iv_text    = |Double-click application event: { COND string( WHEN mv_cfw_events132 = abap_true THEN 'on' ELSE 'off' ) }| ).
          WHEN 'RESIZE'.
            IF mv_cfw_width132 = 420.
              mv_cfw_width132 = 560.
              mv_cfw_height132 = 300.
            ELSE.
              mv_cfw_width132 = 420.
              mv_cfw_height132 = 220.
            ENDIF.
            write_line( io_session = io_session
                        iv_text    = |Editor geometry { mv_cfw_width132 } x { mv_cfw_height132 }| ).
          WHEN 'RUN_TIMER'.
            mv_cfw_timer_running132 = abap_true.
            mo_cfw_timer132->run( ).
            write_line( io_session = io_session
                        iv_text    = 'Session timer started; browser background work is not fabricated' ).
          WHEN 'TICK_TIMER'.
            IF mv_cfw_timer_running132 = abap_true.
              mo_cfw_timer132->tick( ).
              mv_cfw_ticks132 = mo_cfw_timer132->get_tick_count( ).
              write_line( io_session = io_session
                          iv_text    = |Deterministic timer tick { mv_cfw_ticks132 }| ).
            ENDIF.
          WHEN 'REFRESH'.
            mv_refresh = mv_refresh + 1.
            write_line( io_session = io_session
                        iv_text    = |control refresh { mv_refresh }| ).
          WHEN 'RESET'.
            mv_cfw_visible132 = abap_true.
            mv_cfw_enabled132 = abap_true.
            mv_cfw_events132 = abap_true.
            mv_cfw_focus132 = abap_false.
            mv_cfw_timer_running132 = abap_false.
            CLEAR mv_cfw_ticks132.
            IF mo_cfw_timer132 IS BOUND.
              mo_cfw_timer132->reset( ).
            ENDIF.
            write_line( io_session = io_session
                        iv_text    = 'Initial control framework state restored' ).
        ENDCASE.
        build_controls( io_session ).
        set_status( io_session ).
    ENDCASE.
  ENDMETHOD.

  METHOD stop_cfw_resources.
    IF mo_cfw_timer132 IS BOUND.
      mo_cfw_timer132->cancel( ).
      FREE mo_cfw_timer132.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_session_lifecycle_v1~on_close.
    stop_cfw_resources( ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
