CLASS ltcl_ex_19 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_fixed_listbox FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_19 IMPLEMENTATION.

  METHOD builds_fixed_listbox.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_019( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_MODE' ]-value
      exp = 'A' ).
  ENDMETHOD.

ENDCLASS.
