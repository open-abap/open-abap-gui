CLASS ltcl_ex_29 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS updates_parameter_on_output FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_29 IMPLEMENTATION.

  METHOD updates_parameter_on_output.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_29( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CNT' ]-value
      exp = '1' ).
  ENDMETHOD.

ENDCLASS.
