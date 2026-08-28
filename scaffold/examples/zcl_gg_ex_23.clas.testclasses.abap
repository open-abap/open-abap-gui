CLASS ltcl_ex_23 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_line_parameters FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_23 IMPLEMENTATION.

  METHOD builds_line_parameters.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_23( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_LOW' ]-value ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_HIGH' ]-value ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'C01' ]-position
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_LOW' ]-position
      exp = 11 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_HIGH' ]-position
      exp = 40 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_LOW' ]-line
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_HIGH' ]-line
      exp = 1 ).
  ENDMETHOD.

ENDCLASS.
