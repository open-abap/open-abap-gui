CLASS ltcl_ex_56 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resumes_after_transaction FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_56 IMPLEMENTATION.

  METHOD resumes_after_transaction.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_056( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `back` ) ) ).
  ENDMETHOD.

ENDCLASS.
