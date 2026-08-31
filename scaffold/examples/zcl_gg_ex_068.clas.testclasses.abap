CLASS ltcl_ex_68 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS toggles_dynamic_state FOR TESTING.
ENDCLASS.

CLASS ltcl_ex_68 IMPLEMENTATION.

  METHOD toggles_dynamic_state.
    DATA(ls_hidden) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_068( )
      it_input  = VALUE #( ( name = 'P_REQUIRED' value = 'ready' ) ) ).
    cl_abap_unit_assert=>assert_false( ls_hidden-states[ name = 'P_DETAIL' ]-visible ).
    DATA(ls_visible) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_068( )
      it_input  = VALUE #( ( name = 'P_SHOW' value = 'X' )
                          ( name = 'P_REQUIRED' value = 'ready' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_visible-states[ name = 'P_DETAIL' ]-visible ).
    cl_abap_unit_assert=>assert_true( ls_visible-states[ name = 'P_DETAIL' ]-input ).
    cl_abap_unit_assert=>assert_true( ls_visible-states[ name = 'P_DETAIL' ]-obligatory ).
  ENDMETHOD.
ENDCLASS.
