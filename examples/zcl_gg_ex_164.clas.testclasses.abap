CLASS ltcl_ex_164 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS shows_inbound_initially FOR TESTING.
    METHODS group_shares_user_command FOR TESTING.
    METHODS direction_change_switches FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_164 IMPLEMENTATION.

  METHOD teardown.
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD shows_inbound_initially.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report            = NEW zcl_gg_ex_164( )
      iv_stop_before_start = abap_true
      iv_present_selection = abap_true ).

    cl_abap_unit_assert=>assert_equals( act = ls_result-states[ name = 'S_INQ' ]-modif_id
                                        exp = 'IN' ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'S_INQ' ]-visible ).
    cl_abap_unit_assert=>assert_false( ls_result-states[ name = 'S_OUTQ' ]-visible ).
  ENDMETHOD.

  METHOD group_shares_user_command.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report            = NEW zcl_gg_ex_164( )
      iv_stop_before_start = abap_true
      iv_present_selection = abap_true ).

* USER-COMMAND is declared on P_IN only; selecting P_OUT raises it too.
    cl_abap_unit_assert=>assert_equals( act = ls_result-elements[ name = 'P_OUT' ]-ucomm
                                        exp = 'DIR' ).
  ENDMETHOD.

  METHOD direction_change_switches.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_164( ) ).

* The browser posts only the button it selected, with the group's command.
    DATA(ls_out) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_submit
      ucomm      = 'DIR'
      values     = VALUE #( ( name = 'P_OUT' value = 'X' ) ) ) ).

    cl_abap_unit_assert=>assert_true( ls_out-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_out-page_kind
                                        exp = zif_gg_host_html_v1=>page_selection ).
    cl_abap_unit_assert=>assert_initial( ls_out-compatibility-values[ name = 'P_IN' ]-value ).
    cl_abap_unit_assert=>assert_equals( act = ls_out-compatibility-values[ name = 'P_OUT' ]-value
                                        exp = 'X' ).
    cl_abap_unit_assert=>assert_false( ls_out-compatibility-states[ name = 'S_INQ' ]-visible ).
    cl_abap_unit_assert=>assert_true( ls_out-compatibility-states[ name = 'S_OUTQ' ]-visible ).

    DATA(ls_in) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_out-session_id
      page_id    = ls_out-page_id
      action     = zif_gg_host_html_v1=>action_submit
      ucomm      = 'DIR'
      values     = VALUE #( ( name = 'P_IN' value = 'X' ) ) ) ).

    cl_abap_unit_assert=>assert_initial( ls_in-compatibility-values[ name = 'P_OUT' ]-value ).
    cl_abap_unit_assert=>assert_true( ls_in-compatibility-states[ name = 'S_INQ' ]-visible ).
    cl_abap_unit_assert=>assert_false( ls_in-compatibility-states[ name = 'S_OUTQ' ]-visible ).
  ENDMETHOD.

ENDCLASS.
