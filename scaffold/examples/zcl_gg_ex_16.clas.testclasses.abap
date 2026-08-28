CLASS ltcl_ex_16 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_attribute_parameter FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_16 IMPLEMENTATION.

  METHOD builds_attribute_parameter.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_16( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_NAME' ]-value ).
  ENDMETHOD.

ENDCLASS.
