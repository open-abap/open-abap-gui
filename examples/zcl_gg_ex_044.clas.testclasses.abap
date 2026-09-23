CLASS ltcl_ex_44 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS dispatches_user_command FOR TESTING.
    METHODS html_status_action FOR TESTING.
    METHODS runtime_authorizes_commands FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_44 IMPLEMENTATION.

  METHOD dispatches_user_command.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report       = NEW zcl_gg_ex_044( )
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
      act = ls_result-status-active_ucomm[ 2 ]
      exp = 'REFR' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-excluded_ucomm[ 1 ]
      exp = 'DEL' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-status-icon_bar )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 1 ]-ucomm
      exp = 'REFR' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 1 ]-label
      exp = 'Refresh' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 1 ]-icon
      exp = 'refresh' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 1 ]-separator
      exp = abap_false ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 2 ]-icon
      exp = 'printer' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 2 ]-ucomm
      exp = 'PRI' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 2 ]-label
      exp = 'Print' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status-icon_bar[ 2 ]-separator
      exp = abap_true ).

    DATA(ls_empty) = zcl_gg_host=>run( NEW zcl_gg_ex_001( ) ).
    cl_abap_unit_assert=>assert_initial( ls_empty-status-icon_bar ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_empty-html CS 'class="wb-toolbar-button' ) ).
  ENDMETHOD.

  METHOD html_status_action.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_044( ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'value="COMMAND:DEL"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'value="COMMAND:DEL" disabled' ) ).
  ENDMETHOD.

  METHOD runtime_authorizes_commands.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_044( ) ).

    DATA(ls_inactive) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = zif_gg_session_types_v1=>command_save ) ).
    cl_abap_unit_assert=>assert_false( ls_inactive-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_inactive-error
      exp = 'Command is not active for the current host page' ).

    DATA(ls_excluded) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = 'DEL' ) ).
    cl_abap_unit_assert=>assert_false( ls_excluded-valid ).

    DATA(ls_allowed) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = 'REFR' ) ).
    cl_abap_unit_assert=>assert_true( ls_allowed-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_allowed-compatibility-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `body` )
        ( `refreshed` ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
