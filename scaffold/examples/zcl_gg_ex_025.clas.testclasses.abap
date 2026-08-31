CLASS ltcl_ex_25 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_function_key FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_25 IMPLEMENTATION.

  METHOD builds_function_key.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_025( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'FUNCTION_KEY' ]-number
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'FUNCTION_KEY' ]-text
      exp = 'Extras' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'FUNCTION_KEY' ]-ucomm
      exp = 'FC01' ).
  ENDMETHOD.

ENDCLASS.
