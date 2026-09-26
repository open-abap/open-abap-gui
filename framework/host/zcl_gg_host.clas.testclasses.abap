CLASS lcl_report DEFINITION FINAL CREATE PUBLIC.

* One self contained report, switched by mode, standing in for the example
* classes until phase 1 of examples/PLAN.md creates them. It implements the
* interfaces directly and spells out every method, the shape the plan requires.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.

    METHODS writer
      IMPORTING
        io_session       TYPE REF TO zif_gg_session_v1
      RETURNING
        VALUE(ro_writer) TYPE REF TO zif_gg_list_writer_v1.

ENDCLASS.

CLASS lcl_report IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD writer.
    ro_writer = io_session->get_list( )->get_writer( ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA lo_writer TYPE REF TO zif_gg_list_writer_v1.
    DATA lo_gui_container TYPE REF TO cl_gui_custom_container.
    DATA lo_gui_textedit TYPE REF TO cl_gui_textedit.
    DATA lo_gui_tree TYPE REF TO cl_gui_alv_tree.
    DATA lv_gui_node TYPE lvc_nkey.
    DATA lo_gui_grid TYPE REF TO cl_gui_alv_grid.
    DATA lt_gui_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_gui_fcat TYPE lvc_t_fcat.
    DATA lo_gui_viewer TYPE REF TO cl_gui_html_viewer.
    DATA lt_gui_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    lo_writer = writer( io_session ).

    CASE mv_mode.
      WHEN 'HELLO'.
        lo_writer->write_field( VALUE #( text = 'hello world' ) ).

      WHEN 'ESCAPE'.
        lo_writer->write_field( VALUE #( text = '<x a="b">' ) ).

      WHEN 'PLACE'.
        lo_writer->write_field( VALUE #(
          text      = 'abcdefgh'
          placement = VALUE #( position = 10 length = 5 ) ) ).
        lo_writer->write_field( VALUE #(
          text      = 'x'
          placement = VALUE #( no_gap = abap_true ) ) ).
        lo_writer->write_field( VALUE #( text = 'y' ) ).

      WHEN 'SKIP'.
        lo_writer->write_field( VALUE #( text = 'first' ) ).
        lo_writer->skip( 2 ).
        lo_writer->uline( VALUE #( position = 1 length = 20 ) ).
        lo_writer->new_line( ).
        lo_writer->write_field( VALUE #( text = 'second' ) ).

      WHEN 'STOP'.
        lo_writer->write_field( VALUE #( text = 'before' ) ).
        io_session->stop( ).
        lo_writer->write_field( VALUE #( text = 'unreachable' ) ).

      WHEN 'TERMINAL'.
        io_session->get_navigation( )->leave_program( ).

      WHEN 'PAGE'.
        lo_writer->write_field( VALUE #( text = 'body' ) ).

      WHEN 'DEFAULT'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_CARR' ]-value ) ).

      WHEN 'MESSAGE'.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'bad input' ) ).

      WHEN 'GUI'.
        lo_gui_container = NEW cl_gui_custom_container( container_name = 'HOST_GUI' ).
        lo_gui_textedit = NEW cl_gui_textedit(
          parent                     = lo_gui_container
          wordwrap_to_linebreak_mode = 0 ).
        lo_gui_textedit->set_textstream( '<report text>' ).
        lo_gui_tree = NEW cl_gui_alv_tree( parent = lo_gui_container ).
        lo_gui_tree->add_node(
          EXPORTING
            i_relat_node_key = ''
            i_relationship   = cl_tree_control_base=>relat_first_child
            i_node_text      = '<report root>'
          IMPORTING
            e_new_node_key   = lv_gui_node ).
        lo_gui_grid = NEW cl_gui_alv_grid( i_parent = lo_gui_container ).
        APPEND '<report row>' TO lt_gui_rows.
        APPEND VALUE #( fieldname = 'VALUE' coltext = 'Value' ) TO lt_gui_fcat.
        lo_gui_grid->set_table_for_first_display(
          CHANGING
            it_outtab       = lt_gui_rows
            it_fieldcatalog = lt_gui_fcat ).
        lo_gui_viewer = NEW cl_gui_html_viewer( parent = lo_gui_container ).
        APPEND '<b>viewer</b>' TO lt_gui_html.
        lo_gui_viewer->load_data( CHANGING data_table = lt_gui_html ).
        lo_writer->write_field( VALUE #( text = 'GUI report' ) ).

      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    IF mv_mode = 'STOP'.
      writer( io_session )->write_field( VALUE #(
        text      = 'end'
        placement = VALUE #( new_line = abap_true ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    IF mv_mode = 'PAGE'.
      ro_list_processing = me.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    CASE mv_mode.
      WHEN 'DEFAULT'.
        io_builder->add_parameter( VALUE #(
          name      = 'P_CARR'
          text      = 'Carrier'
          data_type = VALUE #( typ = 'C' length = 3 )
          default   = 'LH' ) ).
      WHEN 'REQUIRED'.
        io_builder->add_parameter( VALUE #(
          name       = 'P_CARR'
          text       = 'Carrier'
          data_type  = VALUE #( typ = 'C' length = 3 )
          obligatory = abap_true ) ).
      WHEN 'OUTPUT'.
        io_builder->add_parameter( VALUE #(
          name       = 'P_CARR'
          text       = 'Carrier'
          data_type  = VALUE #( typ = 'C' length = 3 )
          obligatory = abap_true ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    IF mv_mode = 'DEFAULT'.
      ct_values[ name = 'P_CARR' ]-value = 'AA'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    writer( io_session )->write_field( VALUE #( text = 'header' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    IF mv_mode = 'HELLO'.
      io_session->get_list( )->set_title( 'Host list' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    IF mv_mode = 'OUTPUT'.
      ct_values[ name = 'P_CARR' ]-value = 'OUT'.
      ct_states[ name = 'P_CARR' ]-visible = abap_false.
      ct_states[ name = 'P_CARR' ]-enabled = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    IF mv_mode = 'OUTPUT'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'Output mutation test' ) ).
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

  METHOD zif_gg_list_processing_v1~get_settings.
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
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_host DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS write_literal FOR TESTING.
    METHODS placement_and_gap FOR TESTING.
    METHODS skip_and_uline FOR TESTING.
    METHODS stop_reaches_end FOR TESTING.
    METHODS top_of_page_first FOR TESTING.
    METHODS default_then_initialization FOR TESTING.
    METHODS error_message_recorded FOR TESTING.
    METHODS html_list FOR TESTING.
    METHODS html_selection FOR TESTING.
    METHODS html_escapes_output FOR TESTING.
    METHODS runtime_rejects_stale_page FOR TESTING.
    METHODS terminal_page FOR TESTING.
    METHODS selection_output_snapshot FOR TESTING.
    METHODS selection_renderer_controls FOR TESTING.
    METHODS selection_sibling_blocks FOR TESTING.
    METHODS html_gui_fixture FOR TESTING.
    METHODS replaces_a_host_session FOR TESTING.

ENDCLASS.

CLASS ltcl_host IMPLEMENTATION.

  METHOD write_literal.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'HELLO' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `hello world` ) ) ).
  ENDMETHOD.

  METHOD placement_and_gap.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'PLACE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `         abcde xy` ) ) ).
  ENDMETHOD.

  METHOD skip_and_uline.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'SKIP' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `first` )
        ( `` )
        ( `` )
        ( `--------------------` )
        ( `second` ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-model_events[ kind = 'SKIP' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-model_events[ kind = 'ULINE' ] ) ) ).
  ENDMETHOD.

  METHOD stop_reaches_end.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'STOP' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `before` )
        ( `end` ) ) ).
  ENDMETHOD.

  METHOD top_of_page_first.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'PAGE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `header` )
        ( `body` ) ) ).
  ENDMETHOD.

  METHOD default_then_initialization.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'DEFAULT' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `AA` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-value
      exp = 'AA' ).
  ENDMETHOD.

  METHOD error_message_recorded.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'MESSAGE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'bad input' ).
    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

  METHOD html_list.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'HELLO' ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<!doctype html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-page-kind="LIST"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'hello world' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="gg-status-region"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="gg-message-region"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="gg-work-area"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="gg-list-page-header"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Host list</span><span class="gg-list-page-number"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'aria-label="Page 1">1</span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="gg-action-row"' ) ).
  ENDMETHOD.

  METHOD html_selection.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'REQUIRED' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-page_kind
      exp = zif_gg_host_html_v1=>page_selection ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<form method="post" action="/dispatch">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'name="P_CARR"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'required' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'gg-state-required' ) ).
  ENDMETHOD.

  METHOD html_escapes_output.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'ESCAPE' ) ).

    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS '<x a="b">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '&lt;x a=&quot;b&quot;&gt;' ) ).
  ENDMETHOD.

  METHOD runtime_rejects_stale_page.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_report( 'HELLO' ) ).
    DATA(ls_stale) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-current_page-session_id
      page_id    = 'wrong'
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_false( ls_stale-valid ).
    DATA(ls_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-current_page-session_id
      page_id    = ls_start-current_page-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_next-valid ).
    cl_abap_unit_assert=>assert_not_initial( ls_next-html ).
    DATA(ls_unknown) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_next-current_page-session_id
      page_id    = ls_next-current_page-page_id
      action     = 'NOPE' ) ).
    cl_abap_unit_assert=>assert_false( ls_unknown-valid ).
    DATA(ls_duplicate) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-current_page-session_id
      page_id    = ls_start-current_page-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_false( ls_duplicate-valid ).
    DATA(ls_missing) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = 'missing'
      page_id    = 'missing'
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_false( ls_missing-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD terminal_page.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'TERMINAL' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-page_kind
      exp = zif_gg_host_html_v1=>page_terminal ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'LEAVE PROGRAM' ) ).
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_report( 'TERMINAL' ) ).
    DATA(ls_after) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-current_page-session_id
      page_id    = ls_start-current_page-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_false( ls_after-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD selection_output_snapshot.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'OUTPUT' ) ).

    cl_abap_unit_assert=>assert_true( ls_result-selection_active ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-screen_snapshot-values[ name = 'P_CARR' ]-value
      exp = 'OUT' ).
    cl_abap_unit_assert=>assert_false( ls_result-screen_snapshot-states[ name = 'P_CARR' ]-visible ).
    cl_abap_unit_assert=>assert_false( ls_result-screen_snapshot-states[ name = 'P_CARR' ]-enabled ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-page-kind="SELECTION"' ) ).
  ENDMETHOD.

  METHOD selection_renderer_controls.
    DATA(lo_screen) = NEW zcl_gg_host_screen( ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_checkbox( VALUE #(
      name = 'P_CHECK' text = 'Check' default = abap_true ucomm = 'CHECK' ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_radiobutton( VALUE #(
      name = 'P_ONE' text = 'One' default = abap_true radio_group = 'GRP' ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_radiobutton( VALUE #(
      name = 'P_TWO' text = 'Two' radio_group = 'GRP' ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_listbox( VALUE #(
      name = 'P_LIST' text = 'List' default = 'A'
      fixed_values = VALUE #( ( key = 'A' text = '<A>' ) ) ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_pushbutton( VALUE #(
      name = 'PB' text = 'Go' ucomm = 'GO' ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~begin_tabbed_block( VALUE #( name = 'TABS' lines = 2 ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_tab( VALUE #(
      name = 'TAB_A' text = 'A' ucomm = 'TAB_A' ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~end_tabbed_block( ).
    DATA(lv_html) = zcl_gg_host_renderer=>render_selection(
      iv_session_id = 'S'
      iv_page_id    = 'P'
      iv_title      = 'Selection'
      it_values     = lo_screen->get_values( )
      it_states     = lo_screen->get_states( )
      it_blocks     = lo_screen->get_blocks( )
      it_elements   = lo_screen->get_elements( )
      it_tabs       = lo_screen->get_tabs( )
      iv_help_text  = 'Instructions' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'type="checkbox"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-radio-GRP' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;A&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'role="tablist"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<label for=' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label=' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="gg-instruction-region"' ) ).
  ENDMETHOD.

  METHOD selection_sibling_blocks.
    DATA(lo_screen) = NEW zcl_gg_host_screen( ).
    lo_screen->zif_gg_selection_screen_builder_v1~begin_block( VALUE #(
      name = 'BLOCK1' title = 'First' with_frame = abap_true ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_parameter( VALUE #(
      name = 'P_MAXRUN' text = 'Max' data_type = VALUE #( typ = 'I' ) ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~end_block( ).
    lo_screen->zif_gg_selection_screen_builder_v1~begin_block( VALUE #(
      name = 'BLOCK2' title = 'Second' with_frame = abap_true ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~add_parameter( VALUE #(
      name = 'P_BKDEF' text = 'Default' data_type = VALUE #( typ = 'I' ) ) ).
    lo_screen->zif_gg_selection_screen_builder_v1~end_block( ).
    DATA(lv_html) = zcl_gg_host_renderer=>render_selection(
      iv_session_id = 'S'
      iv_page_id    = 'P'
      iv_title      = 'Selection'
      it_values     = lo_screen->get_values( )
      it_states     = lo_screen->get_states( )
      it_blocks     = lo_screen->get_blocks( )
      it_elements   = lo_screen->get_elements( )
      it_tabs       = lo_screen->get_tabs( ) ).
    FIND ALL OCCURRENCES OF '<fieldset>' IN lv_html MATCH COUNT DATA(lv_open).
    FIND ALL OCCURRENCES OF '</fieldset>' IN lv_html MATCH COUNT DATA(lv_close).
    cl_abap_unit_assert=>assert_equals(
      act = lv_open
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_close
      exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<legend>First</legend>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<legend>Second</legend>' ) ).
    FIND '<legend>Second</legend>' IN lv_html MATCH OFFSET DATA(lv_second).
    FIND 'P_MAXRUN' IN lv_html MATCH OFFSET DATA(lv_first_field).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_second > lv_first_field ) ).
  ENDMETHOD.

  METHOD html_gui_fixture.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'GUI' ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<!doctype html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'GUI report' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<textarea' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'gg-alv' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'role="tree"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'sandbox=""' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS '<report text>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS '<report root>' ) ).
  ENDMETHOD.

  METHOD replaces_a_host_session.
    DATA ls_old TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_new TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_stale TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_request TYPE zif_gg_host_html_v1=>ty_request.

    zcl_gg_host_runtime=>clear( ).
    ls_old = zcl_gg_host_runtime=>start( io_report = NEW lcl_report( 'HELLO' ) ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_gg_host_runtime=>close_current(
        iv_session_id = ls_old-session_id
        iv_page_id    = ls_old-page_id ) ).
    ls_new = zcl_gg_host_runtime=>start( io_report = NEW lcl_report( 'PLACE' ) ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_new-session_id ).
    ls_request-session_id = ls_old-session_id.
    ls_request-page_id = ls_old-page_id.
    ls_request-action = zif_gg_host_html_v1=>action_submit.
    ls_stale = zcl_gg_host_runtime=>dispatch( ls_request ).
    cl_abap_unit_assert=>assert_false( act = ls_stale-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
