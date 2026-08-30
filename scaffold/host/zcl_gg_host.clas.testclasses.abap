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
          parent = lo_gui_container
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
    RETURN.
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
        type  = zif_gg_session_types_v1=>message_type_error
        text  = 'Output mutation test' ) ).
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
    METHODS list_model_and_token FOR TESTING.
    METHODS list_model_coverage FOR TESTING.
    METHODS selection_output_snapshot FOR TESTING.
    METHODS html_status_action FOR TESTING.
    METHODS runtime_authorizes_commands FOR TESTING.
    METHODS runtime_authorizes_pf_keys FOR TESTING.
    METHODS runtime_history_back FOR TESTING.
    METHODS dynpro_runtime FOR TESTING.
    METHODS navigation_metadata FOR TESTING.
    METHODS runtime_navigation_roundtrips FOR TESTING.
    METHODS structured_memory_list FOR TESTING.
    METHODS selection_renderer_controls FOR TESTING.
    METHODS html_display_like FOR TESTING.
    METHODS html_gui_fixture FOR TESTING.

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
  ENDMETHOD.

  METHOD html_selection.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'REQUIRED' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-page_kind
      exp = zif_gg_host_html_v1=>page_selection ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<form method="post" action="/dispatch">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'name="P_CARR"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'required' ) ).
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
      page_id = 'missing'
      action = zif_gg_host_html_v1=>action_submit ) ).
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

  METHOD list_model_and_token.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_43( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-model_events[ 1 ]-kind
      exp = 'PAGE_BEGIN' ).
    cl_abap_unit_assert=>assert_not_initial( ls_result-render_lines[ 1 ]-token ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-action-token=' ) ).

    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_43( ) ).
    DATA(ls_invalid) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_line
      row        = 1
      token      = 'wrong' ) ).
    cl_abap_unit_assert=>assert_false( ls_invalid-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD list_model_coverage.
    DATA(ls_placement) = zcl_gg_host=>run( NEW zcl_gg_ex_02( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_placement-render_lines[ 1 ]-fragments[ 1 ]-position
      exp = 10 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_placement-render_lines[ 1 ]-fragments[ 1 ]-length
      exp = 5 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lines( ls_placement-render_lines[ 1 ]-fragments ) >= 3 ) ).

    DATA(ls_pages) = zcl_gg_host=>run( NEW zcl_gg_ex_08( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lines( ls_pages-render_lines ) >= 2 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_pages-model_events[ kind = 'PAGE_BEGIN' page = 2 ] ) ) ).

    DATA(ls_hidden) = zcl_gg_host=>run( NEW zcl_gg_ex_43( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_hidden-render_lines[ 1 ]-fields[ name = 'GV_ID' ]-value
      exp = '1' ).

    DATA(ls_modified) = zcl_gg_host=>run(
      io_report     = NEW zcl_gg_ex_46( )
      iv_line_index = 1 ).
    cl_abap_unit_assert=>assert_true( act = ls_modified-line_formats[ 1 ]-intensified ).
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

  METHOD html_status_action.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_44( ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'value="COMMAND:DEL"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'value="COMMAND:DEL" disabled' ) ).
  ENDMETHOD.

  METHOD runtime_authorizes_commands.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_44( ) ).

    DATA(ls_inactive) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = zif_gg_session_types_v1=>command_save ) ).
    cl_abap_unit_assert=>assert_false( ls_inactive-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_inactive-error
      exp = 'Command is not active for the current host page' ).

    DATA(ls_excluded) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = 'DEL' ) ).
    cl_abap_unit_assert=>assert_false( ls_excluded-valid ).

    DATA(ls_allowed) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = 'REFR' ) ).
    cl_abap_unit_assert=>assert_true( ls_allowed-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_allowed-compatibility-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `body` )
        ( `refreshed` ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD runtime_authorizes_pf_keys.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_49( ) ).

    DATA(ls_disabled) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_pf
      pf_key     = 6 ) ).
    cl_abap_unit_assert=>assert_false( ls_disabled-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_disabled-error
      exp = 'PF key is not active for the current host page' ).

    DATA(ls_allowed) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_pf
      pf_key     = 5 ) ).
    cl_abap_unit_assert=>assert_true( ls_allowed-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_allowed-compatibility-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `body` )
        ( `pf5` ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD runtime_history_back.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_43( ) ).
    cl_abap_unit_assert=>assert_not_initial( ls_start-compatibility-lines ).
    DATA(ls_detail) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_line
      row        = 1
      token      = 'H-1-1' ) ).
    cl_abap_unit_assert=>assert_true( ls_detail-valid ).
    DATA(ls_back) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_detail-session_id
      page_id    = ls_detail-page_id
      action     = zif_gg_host_html_v1=>action_back ) ).
    cl_abap_unit_assert=>assert_true( ls_back-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-page_id exp = ls_start-page_id ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_back-pages ) exp = 2 ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD dynpro_runtime.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_dynpro_program = NEW zcl_gg_integration_dynpro( ) ).
    cl_abap_unit_assert=>assert_true( ls_start-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_start-page_kind
      exp = zif_gg_host_html_v1=>page_dynpro ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_start-html CS 'data-page-kind="DYNPRO"' ) ).

    DATA(ls_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_submit
      ucomm = 'NEXT' ) ).
    cl_abap_unit_assert=>assert_true( ls_next-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_next-current_page-screen exp = '0200' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_next-html CS 'data-screen="0200"' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD navigation_metadata.
    DATA(ls_selection) = zcl_gg_host=>run( NEW zcl_gg_ex_51( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_selection-navigation-kind
      exp = zcx_gg_control_flow=>kind_call_selection_screen ).
    cl_abap_unit_assert=>assert_equals( act = ls_selection-navigation-target exp = '0500' ).
    cl_abap_unit_assert=>assert_equals( act = ls_selection-navigation-continuation exp = 'AFTER_0500' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_selection-html CS 'gg-navigation' ) ).

    DATA(ls_screen) = zcl_gg_host=>run( NEW zcl_gg_ex_52( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_screen-navigation-kind
      exp = zcx_gg_control_flow=>kind_call_screen ).
    cl_abap_unit_assert=>assert_equals( act = ls_screen-navigation-target exp = '0100' ).

    DATA(ls_submit) = zcl_gg_host=>run( NEW zcl_gg_ex_54( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_submit-navigation-kind
      exp = zcx_gg_control_flow=>kind_submit_return ).
    cl_abap_unit_assert=>assert_equals( act = ls_submit-navigation-target exp = 'ZGG_EX_20' ).

    DATA(ls_transaction) = zcl_gg_host=>run( NEW zcl_gg_ex_56( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-navigation-kind
      exp = zcx_gg_control_flow=>kind_call_transaction ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-navigation-target exp = 'SE38' ).
  ENDMETHOD.

  METHOD runtime_navigation_roundtrips.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_selection) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_51( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_selection-page_kind
      exp = zif_gg_host_html_v1=>page_selection ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_selection-html CS 'name="P_B"' ) ).
    DATA(ls_selection_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_selection-session_id
      page_id    = ls_selection-page_id
      action     = zif_gg_host_html_v1=>action_submit
      values     = VALUE #( ( name = 'P_B' value = 'X' ) ) ) ).
    cl_abap_unit_assert=>assert_true( ls_selection_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_selection_next-compatibility-lines[ table_line = 'X' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).

    DATA(ls_screen) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_52( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_screen-page_kind
      exp = zif_gg_host_html_v1=>page_navigation ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_screen-html CS 'Continue to' ) ).
    DATA(ls_screen_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_screen-session_id
      page_id    = ls_screen-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_screen_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_screen_next-compatibility-lines[ table_line = 'back' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).

    DATA(ls_submit) = zcl_gg_host_runtime=>start(
      io_report        = NEW zcl_gg_ex_54( )
      io_submit_report = NEW lcl_report( 'HELLO' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_submit-page_kind
      exp = zif_gg_host_html_v1=>page_navigation ).
    DATA(ls_submit_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_submit-session_id
      page_id    = ls_submit-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_submit_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_submit_next-compatibility-lines[ table_line = 'back' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).

    DATA(ls_transaction) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_56( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-page_kind
      exp = zif_gg_host_html_v1=>page_navigation ).
    DATA(ls_transaction_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_transaction-session_id
      page_id    = ls_transaction-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_transaction_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_transaction_next-compatibility-lines[ table_line = 'back' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD structured_memory_list.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_55( )
      io_submit_report = NEW lcl_report( 'HELLO' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `hello world` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-memory_render_lines[ 1 ]-text
      exp = `hello world` ).
    cl_abap_unit_assert=>assert_not_initial( ls_result-memory_render_lines[ 1 ]-token ).
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
      iv_page_id = 'P'
      iv_title = 'Selection'
      it_values = lo_screen->get_values( )
      it_states = lo_screen->get_states( )
      it_blocks = lo_screen->get_blocks( )
      it_elements = lo_screen->get_elements( )
      it_tabs = lo_screen->get_tabs( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'type="checkbox"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-radio-GRP' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;A&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'role="tablist"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<label for=' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label=' ) ).
  ENDMETHOD.

  METHOD html_display_like.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_42( ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'gg-error' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'looks like an error' ) ).
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

ENDCLASS.
