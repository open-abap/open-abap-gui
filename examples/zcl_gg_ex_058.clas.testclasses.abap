CLASS ltcl_ex_58 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS set_screen_then_leave FOR TESTING.
    METHODS leave_to_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_58 IMPLEMENTATION.

  METHOD set_screen_then_leave.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_ex_058( )
      iv_ucomm   = 'NEXT' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-screen
      exp = '0200' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE SCREEN' ).
  ENDMETHOD.

  METHOD leave_to_screen.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_ex_058( )
      iv_ucomm   = 'BACK' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-screen
      exp = '0000' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE TO SCREEN 0000' ).
  ENDMETHOD.

ENDCLASS.
