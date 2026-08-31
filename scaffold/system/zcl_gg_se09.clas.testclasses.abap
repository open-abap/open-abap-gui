CLASS ltcl_gg_se09 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS metadata FOR TESTING.
    METHODS displays_server_request FOR TESTING.
    METHODS rejects_unknown_request FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se09 IMPLEMENTATION.

  METHOD metadata.
    DATA(ls_transaction) = NEW zcl_gg_se09( )->zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode exp = 'SE09' ).
  ENDMETHOD.

  METHOD displays_server_request.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se09( )
      iv_ucomm = 'DISPLAY'
      it_values = VALUE #( ( name = 'P_REQUEST' value = 'DEVK900001' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_REQ_ID' ]-value exp = 'DEVK900001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_TASKS' name = 'TASK_TEXT' row = 1 ]-value exp = 'Dictionary inspection task' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Dictionary inspection task' ) ).
  ENDMETHOD.

  METHOD rejects_unknown_request.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se09( )
      iv_ucomm = 'DISPLAY'
      it_values = VALUE #( ( name = 'P_REQUEST' value = 'DEVK999999' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen exp = '0100' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Request is unknown or not authorized for display.' ).
  ENDMETHOD.

ENDCLASS.
