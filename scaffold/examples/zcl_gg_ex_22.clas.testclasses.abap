CLASS ltcl_ex_22 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_block_parameter FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_22 IMPLEMENTATION.

  METHOD builds_block_parameter.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_22( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_A' ]-value ).
  ENDMETHOD.

ENDCLASS.
