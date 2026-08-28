CLASS ltcl_gg_integration_fail DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS handles_empty_database FOR TESTING.
    METHODS handles_invalid_carrier FOR TESTING.
    METHODS handles_reversed_range FOR TESTING.
    METHODS handles_database_failure FOR TESTING.
    METHODS reports_database_failure FOR TESTING.
    METHODS handles_authorization_failure FOR TESTING.
    METHODS reports_authorization_failure FOR TESTING.
    METHODS recovers_after_failure FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_integration_fail IMPLEMENTATION.

  METHOD handles_empty_database.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'NONE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `No flights found` ) ) ).
  ENDMETHOD.

  METHOD handles_invalid_carrier.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'INVALID' )
      it_input = VALUE #( ( name = 'P_CARR' value = 'ZZZ' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Unknown carrier' ).
  ENDMETHOD.

  METHOD handles_reversed_range.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_flights( 'REVERSE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 1 ]
      exp = `No flights found` ).
  ENDMETHOD.

  METHOD handles_database_failure.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_failure( 'DB_FAIL' ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

  METHOD reports_database_failure.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_failure( 'DB_FAIL' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Database unavailable' ).
  ENDMETHOD.

  METHOD handles_authorization_failure.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_failure( 'AUTH_FAIL' ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

  METHOD reports_authorization_failure.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_failure( 'AUTH_FAIL' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Authorization denied' ).
  ENDMETHOD.

  METHOD recovers_after_failure.
    zcl_gg_host=>run( NEW zcl_gg_integration_failure( 'DB_FAIL' ) ).
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_failure( 'VALID' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `Recovered execution` ) ) ).
  ENDMETHOD.

ENDCLASS.
