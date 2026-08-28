CLASS ltcl_ex_21 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_comment_layout FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_21 IMPLEMENTATION.

  METHOD builds_comment_layout.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_21( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_A' ]-value ).
  ENDMETHOD.

ENDCLASS.
