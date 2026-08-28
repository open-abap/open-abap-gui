CLASS ltcl_ex_18 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS defaults_one_radio FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_18 IMPLEMENTATION.

  METHOD defaults_one_radio.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_18( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_ALL' ]-value
      exp = 'X' ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_ONE' ]-value ).
  ENDMETHOD.

ENDCLASS.
