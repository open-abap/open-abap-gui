CLASS ltcl_gg_integration_int DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS renders_flight_list FOR TESTING.
    METHODS asserts_initial_contents FOR TESTING.
    METHODS selects_line FOR TESTING.
    METHODS reports_selected_line_text FOR TESTING.
    METHODS reports_cursor_position FOR TESTING.
    METHODS reports_hidden_values FOR TESTING.
    METHODS reports_detail_list_index FOR TESTING.
    METHODS renders_detail_list FOR TESTING.
    METHODS detail_has_flight FOR TESTING.
    METHODS runs_function_code FOR TESTING.
    METHODS reports_function_code FOR TESTING.
    METHODS retrieves_line_hidden_values FOR TESTING.
    METHODS scopes_hidden_values_to_line FOR TESTING.
    METHODS preserves_line_format FOR TESTING.
    METHODS runs_pf_interaction FOR TESTING.
    METHODS restores_list_level FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_integration_int IMPLEMENTATION.

  METHOD class_setup.
    zcl_gg_integration_db=>create( ).
  ENDMETHOD.

  METHOD setup.
    zcl_gg_integration_db=>reset( ).
  ENDMETHOD.

  METHOD class_teardown.
    zcl_gg_integration_db=>destroy( ).
  ENDMETHOD.

  METHOD renders_flight_list.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_interactive( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 5 ).
  ENDMETHOD.

  METHOD asserts_initial_contents.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_interactive( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `AA/0017 20260101` )
        ( `AA/0018 20260115` )
        ( `LH/0400 20260228` )
        ( `LH/0401 20991231` )
        ( `SQ/0020 20260331` ) ) ).
  ENDMETHOD.

  METHOD selects_line.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 7 ] CS `Selected line:` ) ).
  ENDMETHOD.

  METHOD reports_selected_line_text.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 7 ]
      exp = `Selected line: AA/0018 20260115` ).
  ENDMETHOD.

  METHOD reports_cursor_position.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 9 ]
      exp = `Cursor: CARRID=AA line=2` ).
  ENDMETHOD.

  METHOD reports_hidden_values.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 8 ]
      exp = `Hidden: AA/0018 20260115` ).
  ENDMETHOD.

  METHOD reports_detail_list_index.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 11 ]
      exp = `List level: 1` ).
  ENDMETHOD.

  METHOD renders_detail_list.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 1 ]
      exp = `AA/0017 20260101` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 7 ]
      exp = `Selected line: AA/0018 20260115` ).
  ENDMETHOD.

  METHOD detail_has_flight.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 10 ]
      exp = `Detail flight: AA/0018 20260115` ).
  ENDMETHOD.

  METHOD runs_function_code.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_user_command = 'REFRESH' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 6 ]
      exp = `Function code: REFRESH` ).
  ENDMETHOD.

  METHOD reports_function_code.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_user_command = 'REFRESH' ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 6 ] CS `REFRESH` ) ).
  ENDMETHOD.

  METHOD retrieves_line_hidden_values.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 8 ]
      exp = `Hidden: AA/0017 20260101` ).
  ENDMETHOD.

  METHOD scopes_hidden_values_to_line.
    DATA(ls_first) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 1 ).
    DATA(ls_second) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_first-lines[ 8 ] <> ls_second-lines[ 8 ] ) ).
  ENDMETHOD.

  METHOD preserves_line_format.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_interactive( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-line_formats[ 1 ]-color
      exp = zif_gg_list_processing_types_v1=>color_positive ).
    cl_abap_unit_assert=>assert_true( ls_result-line_formats[ 1 ]-intensified ).
  ENDMETHOD.

  METHOD runs_pf_interaction.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_pf_key = 5 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 6 ]
      exp = `PF key: 5` ).
  ENDMETHOD.

  METHOD restores_list_level.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_interactive( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 12 ]
      exp = `Restored level: 0` ).
  ENDMETHOD.

ENDCLASS.
