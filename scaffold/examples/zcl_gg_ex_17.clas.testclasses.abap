CLASS ltcl_ex_17 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_checkbox_parameter FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_17 IMPLEMENTATION.

  METHOD builds_checkbox_parameter.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_17( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `X` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_TEST' ]-value
      exp = 'X' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<form method="post" action="/dispatch">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-page-kind="LIST"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'aria-label="List output"' ) ).
  ENDMETHOD.

ENDCLASS.
