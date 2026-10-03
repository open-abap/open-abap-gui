CLASS ltcl_ex_70 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS selects_one_branch FOR TESTING.
    METHODS requires_branch_value FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_70 IMPLEMENTATION.

  METHOD selects_one_branch.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_070( )
      it_input  = VALUE #( ( name = 'P_ALL' value = '' )
                          ( name = 'P_ONE' value = 'X' )
                          ( name = 'P_ONEV' value = 'one' )
                          ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_ONEV' ]-visible ).
    cl_abap_unit_assert=>assert_false( ls_result-states[ name = 'P_ALLV' ]-visible ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 1 ]
      exp = 'one' ).
  ENDMETHOD.

  METHOD requires_branch_value.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_070( )
      it_input  = VALUE #( ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_result-selection_active ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Enter a value for all flights' ).
  ENDMETHOD.

ENDCLASS.
