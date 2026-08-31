CLASS ltcl_gg_integration_flights DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS returns_all_fixture_rows FOR TESTING.
    METHODS filters_by_carrier FOR TESTING.
    METHODS filters_by_single_date FOR TESTING.
    METHODS filters_by_date_range FOR TESTING.
    METHODS rejects_reversed_date_range FOR TESTING.
    METHODS filters_by_multiple_carriers FOR TESTING.
    METHODS preserves_fixture_order FOR TESTING.
    METHODS returns_no_result_message FOR TESTING.
    METHODS renders_multiple_rows FOR TESTING.
    METHODS renders_single_row FOR TESTING.
    METHODS renders_numeric_fields FOR TESTING.
    METHODS renders_zero_value FOR TESTING.
    METHODS renders_large_value FOR TESTING.
    METHODS preserves_rounding_output FOR TESTING.
    METHODS renders_date_fields FOR TESTING.
    METHODS renders_wide_text_fields FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_integration_flights IMPLEMENTATION.

  METHOD class_setup.
    zcl_gg_db_helper=>create( ).
  ENDMETHOD.

  METHOD setup.
    zcl_gg_db_helper=>reset( ).
  ENDMETHOD.

  METHOD class_teardown.
    zcl_gg_db_helper=>destroy( ).
  ENDMETHOD.

  METHOD returns_all_fixture_rows.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'ALL' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 5 ).
  ENDMETHOD.

  METHOD filters_by_carrier.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'LH' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `LH/0400 20260228 999999999.99 EUR Frankfurt->Tokyo` )
        ( `LH/0401 20991231 42.50 EUR Munich->Rome` ) ) ).
  ENDMETHOD.

  METHOD filters_by_single_date.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'DATE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `AA/0018 20260115 123.45 USD Chicago->Paris` ) ) ).
  ENDMETHOD.

  METHOD filters_by_date_range.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'RANGE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `AA/0017 20260101 0.00 USD New York->London` )
        ( `AA/0018 20260115 123.45 USD Chicago->Paris` ) ) ).
  ENDMETHOD.

  METHOD rejects_reversed_date_range.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'REVERSE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `No flights found` ) ) ).
  ENDMETHOD.

  METHOD filters_by_multiple_carriers.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'MULTI' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 4 ).
  ENDMETHOD.

  METHOD preserves_fixture_order.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'ALL' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 1 ]
      exp = `AA/0017 20260101 0.00 USD New York->London` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 5 ]
      exp = `SQ/0020 20260331 12.34 SGD Singapore->International Hub` ).
  ENDMETHOD.

  METHOD returns_no_result_message.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'NONE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `No flights found` ) ) ).
  ENDMETHOD.

  METHOD renders_multiple_rows.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'MULTI' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 4 ).
  ENDMETHOD.

  METHOD renders_single_row.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'DATE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 1 ).
  ENDMETHOD.

  METHOD renders_numeric_fields.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'LH' ) ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 1 ] CS `999999999.99` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 2 ] CS `42.50` ) ).
  ENDMETHOD.

  METHOD renders_zero_value.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'RANGE' ) ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 1 ] CS `0.00` ) ).
  ENDMETHOD.

  METHOD renders_large_value.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'LH' ) ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 1 ] CS `999999999.99` ) ).
  ENDMETHOD.

  METHOD preserves_rounding_output.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'ROUND' ) ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 1 ] CS `12.34` ) ).
  ENDMETHOD.

  METHOD renders_date_fields.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'DATE' ) ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 1 ] CS `20260115` ) ).
  ENDMETHOD.

  METHOD renders_wide_text_fields.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'ALL' ) ).

    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-lines[ 5 ] CS `International Hub` ) ).
  ENDMETHOD.

ENDCLASS.
