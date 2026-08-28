CLASS ltcl_ex_25 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_function_key FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_25 IMPLEMENTATION.

  METHOD builds_function_key.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_25( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

ENDCLASS.
