CLASS ltcl_ex_70 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS selects_one_branch FOR TESTING.
ENDCLASS.

CLASS ltcl_ex_70 IMPLEMENTATION.

  METHOD selects_one_branch.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_070( )
      it_input  = VALUE #( ( name = 'P_ONE' value = 'X' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_ONE_VALUE' ]-visible ).
    cl_abap_unit_assert=>assert_false( ls_result-states[ name = 'P_ALL_VALUE' ]-visible ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_ONE_VALUE' ]-obligatory ).
  ENDMETHOD.
ENDCLASS.
