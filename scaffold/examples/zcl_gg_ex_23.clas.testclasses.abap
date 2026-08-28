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
  ENDMETHOD.

ENDCLASS.
