CLASS ltcl_gg_integration_selection DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS applies_default FOR TESTING.
    METHODS accepts_required_field FOR TESTING.
    METHODS rejects_missing_required_field FOR TESTING.
    METHODS reports_empty_required_field FOR TESTING.
    METHODS rejects_invalid_input FOR TESTING.
    METHODS returns_to_selection_screen FOR TESTING.
    METHODS restarts_after_error FOR TESTING.
    METHODS filters_by_range FOR TESTING.
    METHODS filters_by_multiple_selection FOR TESTING.
    METHODS retains_values_after_error FOR TESTING.
    METHODS requests_carrier_values FOR TESTING.
    METHODS applies_value_selection FOR TESTING.
    METHODS requests_date_values FOR TESTING.
    METHODS cancelled_request_keeps_value FOR TESTING.
    METHODS handles_unknown_request FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_integration_selection IMPLEMENTATION.

  METHOD class_setup.
    zcl_gg_db_helper=>create( ).
  ENDMETHOD.

  METHOD setup.
    zcl_gg_db_helper=>reset( ).
  ENDMETHOD.

  METHOD class_teardown.
    zcl_gg_db_helper=>destroy( ).
  ENDMETHOD.

  METHOD applies_default.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_selection( 'DEFAULT' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-value
      exp = 'LH' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `LH/0400` )
        ( `LH/0401` ) ) ).
  ENDMETHOD.

  METHOD accepts_required_field.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'REQUIRED' )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'AA' ) ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-messages ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 2 ).
  ENDMETHOD.

  METHOD rejects_missing_required_field.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_selection( 'REQUIRED' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

  METHOD reports_empty_required_field.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_selection( 'REQUIRED' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-field
      exp = 'P_CARR' ).
  ENDMETHOD.

  METHOD rejects_invalid_input.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'INVALID' )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'ZZZ' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Unknown carrier' ).
    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

  METHOD returns_to_selection_screen.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'INVALID' )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'ZZZ' ) ) ).

    cl_abap_unit_assert=>assert_true( ls_result-selection_active ).
  ENDMETHOD.

  METHOD restarts_after_error.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'INVALID' )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'ZZZ' ) )
      it_retry_input = VALUE #( ( name = 'P_CARR' value = 'AA' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `AA/0017` )
        ( `AA/0018` ) ) ).
    cl_abap_unit_assert=>assert_false( ls_result-selection_active ).
  ENDMETHOD.

  METHOD filters_by_range.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'RANGE' )
      it_input  = VALUE #( ( name = 'S_CARR'
                             ranges = VALUE #( (
                               sign = 'I' option = 'BT' low = 'AA' high = 'LH' ) ) ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 4 ).
  ENDMETHOD.

  METHOD filters_by_multiple_selection.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'MULTI' )
      it_input  = VALUE #( ( name = 'S_CARR'
                             ranges = VALUE #(
                               ( sign = 'I' option = 'EQ' low = 'AA' )
                               ( sign = 'I' option = 'EQ' low = 'SQ' ) ) ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `AA/0017` )
        ( `AA/0018` )
        ( `SQ/0020` ) ) ).
  ENDMETHOD.

  METHOD retains_values_after_error.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'INVALID' )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'ZZZ' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-value
      exp = 'ZZZ' ).
  ENDMETHOD.

  METHOD requests_carrier_values.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report       = NEW zcl_gg_integration_selection( 'VALUE_REQUEST' )
      iv_value_request = 'S_CARR' ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-values[ name = 'S_CARR' ]-ranges )
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARR' ]-ranges[ 1 ]-low
      exp = 'AA' ).
  ENDMETHOD.

  METHOD applies_value_selection.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report       = NEW zcl_gg_integration_selection( 'VALUE_REQUEST' )
      iv_value_request = 'S_CARR' ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 5 ).
  ENDMETHOD.

  METHOD requests_date_values.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report       = NEW zcl_gg_integration_selection( 'DATE_REQUEST' )
      iv_value_request = 'S_DATE' ).

    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'S_DATE' ]-ranges ).
  ENDMETHOD.

  METHOD cancelled_request_keeps_value.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'CANCEL_VALUE' )
      iv_value_request = 'S_CARR' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARR' ]-ranges[ 1 ]-low
      exp = 'AA' ).
  ENDMETHOD.

  METHOD handles_unknown_request.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report       = NEW zcl_gg_integration_selection( 'VALUE_REQUEST' )
      iv_value_request = 'UNKNOWN' ).

    cl_abap_unit_assert=>assert_initial( ls_result-messages ).
  ENDMETHOD.

ENDCLASS.
