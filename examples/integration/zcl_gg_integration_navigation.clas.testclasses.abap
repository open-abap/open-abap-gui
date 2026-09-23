CLASS ltcl_gg_integration_nav DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS calls_transaction FOR TESTING.
    METHODS records_transaction_params FOR TESTING.
    METHODS resumes_call FOR TESTING.
    METHODS leaves_transaction FOR TESTING.
    METHODS does_not_return_after_leave FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_integration_nav IMPLEMENTATION.

  METHOD calls_transaction.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_navigation( 'CALL' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-transaction_call-tcode
      exp = 'SE38' ).
  ENDMETHOD.

  METHOD records_transaction_params.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_navigation( 'CALL' ) ).

    cl_abap_unit_assert=>assert_true( ls_result-transaction_call-skip_first_screen ).
  ENDMETHOD.

  METHOD resumes_call.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_navigation( 'CALL' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `Returned from transaction` ) ) ).
  ENDMETHOD.

  METHOD leaves_transaction.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_navigation( 'LEAVE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE TO TRANSACTION ZFLIGHT' ).
  ENDMETHOD.

  METHOD does_not_return_after_leave.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_navigation( 'LEAVE' ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

ENDCLASS.
