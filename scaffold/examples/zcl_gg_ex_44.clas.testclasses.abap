CLASS ltcl_ex_44 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS dispatches_user_command FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_44 IMPLEMENTATION.

  METHOD dispatches_user_command.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report      = NEW zcl_gg_ex_44( )
      iv_user_command = 'REFR' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `body` )
        ( `refreshed` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-status
      exp = 'LIST' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-active_ucomm[ 1 ]
      exp = 'PRI' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-excluded_ucomm[ 1 ]
      exp = 'DEL' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 1 ]-ucomm
      exp = 'REFR' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 2 ]-icon
      exp = 'printer' ).
  ENDMETHOD.

ENDCLASS.
