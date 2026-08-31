CLASS ltcl_ex_64 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS publishes_shell_focus FOR TESTING.
    METHODS rejects_forged_command FOR TESTING.
ENDCLASS.
CLASS ltcl_ex_64 IMPLEMENTATION.
  METHOD publishes_shell_focus.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program   = NEW zcl_gg_ex_064( )
      iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-title exp = 'Feedback 64 - next action' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-status exp = 'SHELL64' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-cursor-field exp = 'P_ACTION' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-cursor-field="P_ACTION"' ) ).
    DATA(ls_submitted) = zcl_gg_host_dynpro=>run(
      io_program   = NEW zcl_gg_ex_064( )
      iv_ucomm     = 'NEXT64'
      iv_submitted = abap_true
      it_values    = VALUE #( ( name = 'P_ACTION' value = 'go' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_submitted-values[ name = 'P_ACTION' ]-value
      exp = 'accepted' ).
  ENDMETHOD.

  METHOD rejects_forged_command.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_ex_064( )
      iv_ucomm   = 'FORGED' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( line_exists( ls_result-messages[
        text = 'Command FORGED is not available on dynpro screen 0100' ] ) ) ).
  ENDMETHOD.
ENDCLASS.
