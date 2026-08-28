CLASS ltcl_ex_27 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_named_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_27 IMPLEMENTATION.

  METHOD builds_named_screen.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_27( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_B' ]-value ).
  ENDMETHOD.

ENDCLASS.
