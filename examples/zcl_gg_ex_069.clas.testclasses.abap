CLASS ltcl_ex_69 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS checkbox_locks_group FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_69 IMPLEMENTATION.

  METHOD checkbox_locks_group.
    DATA(ls_enabled) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_069( )
      it_input  = VALUE #( ( name = 'P_ENABLE' value = 'X' )
                          ( name = 'P_GRP_A' value = 'a' )
                          ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_enabled-states[ name = 'P_GRP_A' ]-input ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_enabled-lines[ 1 ]
      exp = 'a' ).

    DATA(ls_disabled) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_069( )
      it_input  = VALUE #( ( name = 'P_ENABLE' value = '' )
                          ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_false( ls_disabled-states[ name = 'P_GRP_A' ]-input ).
    cl_abap_unit_assert=>assert_false( ls_disabled-states[ name = 'P_GRP_B' ]-input ).
  ENDMETHOD.

ENDCLASS.
