CLASS ltcl_ex_27 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_named_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_27 IMPLEMENTATION.

  METHOD builds_named_screen.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_027( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_B' ]-value ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'SCREEN' ]-screen
      exp = '0500' ).
    cl_abap_unit_assert=>assert_true( ls_result-elements[ kind = 'SCREEN' ]-as_window ).
    cl_abap_unit_assert=>assert_false( ls_result-elements[ kind = 'SCREEN' ]-as_subscreen ).
  ENDMETHOD.

ENDCLASS.
