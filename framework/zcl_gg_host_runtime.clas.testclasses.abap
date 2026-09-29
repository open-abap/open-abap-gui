* A report that opens its own screen 2000 with CALL SCREEN, as a converted
* maintenance report does. Back on the screen runs LEAVE TO SCREEN 0.
CLASS lcl_called_screen DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_screen_provider_v1.
    INTERFACES zif_gg_resumable_v1.

    METHODS constructor
      IMPORTING
        iv_write_after TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_write_after TYPE abap_bool.

ENDCLASS.

CLASS lcl_called_screen IMPLEMENTATION.

  METHOD constructor.
    mv_write_after = iv_write_after.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_dialog( )->call_screen(
      is_call         = VALUE #( screen = '2000' )
      is_continuation = VALUE #( id = 'AFTER_2000' ) ).
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_2000' AND mv_write_after = abap_true.
      io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'after 2000' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~get_initial_screen.
    rv_screen = '2000'.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '2000' title = 'Maintain' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~build_flow_logic.
    io_builder->begin_screen( '2000' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'STATUS_2000' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'USER_COMMAND_2000' on_input = abap_true ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_output_module.
    io_session->get_dialog( )->set_title( 'Maintain' ).
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_input_module.
    IF is_context-ucomm = 'BACK'.
      io_session->get_dialog( )->leave_to_screen( '0000' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_on_value_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_on_help_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    RETURN.
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

ENDCLASS.

CLASS ltcl_runtime DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS opens_called_screen FOR TESTING.
    METHODS screen_0_continues_report FOR TESTING.
    METHODS screen_0_ends_empty_report FOR TESTING.

    METHODS back
      IMPORTING
        is_page            TYPE zif_gg_host_html_v1=>ty_response
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

ENDCLASS.

CLASS ltcl_runtime IMPLEMENTATION.

  METHOD teardown.
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD back.
    rs_response = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = is_page-session_id
      page_id    = is_page-page_id
      action     = zif_gg_host_html_v1=>action_back
      ucomm      = 'BACK' ) ).
  ENDMETHOD.

  METHOD opens_called_screen.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen( abap_true ) ).

    cl_abap_unit_assert=>assert_equals( act = ls_start-page_kind
                                        exp = zif_gg_host_html_v1=>page_dynpro ).
    cl_abap_unit_assert=>assert_equals( act = ls_start-current_page-screen
                                        exp = '2000' ).
  ENDMETHOD.

  METHOD screen_0_continues_report.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen( abap_true ) ).

    DATA(ls_back) = back( ls_start ).

    cl_abap_unit_assert=>assert_true( ls_back-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-page_kind
                                        exp = zif_gg_host_html_v1=>page_list ).
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      line_exists( ls_back-compatibility-lines[ table_line = 'after 2000' ] ) ) ).
  ENDMETHOD.

  METHOD screen_0_ends_empty_report.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen( abap_false ) ).

    DATA(ls_back) = back( ls_start ).

    cl_abap_unit_assert=>assert_true( ls_back-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-page_kind
                                        exp = zif_gg_host_html_v1=>page_terminal ).
    cl_abap_unit_assert=>assert_true( ls_back-current_page-terminal ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_back-html CS 'Maintain' ) ).

    DATA(ls_after) = back( ls_back ).
    cl_abap_unit_assert=>assert_false( ls_after-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_after-error
                                        exp = 'Host session is terminal' ).
  ENDMETHOD.

ENDCLASS.
