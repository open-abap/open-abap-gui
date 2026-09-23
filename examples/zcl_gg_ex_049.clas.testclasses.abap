CLASS ltcl_ex_49 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS dispatches_pf5 FOR TESTING.
    METHODS runtime_authorizes_pf_keys FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_49 IMPLEMENTATION.

  METHOD dispatches_pf5.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_049( )
      iv_pf_key = 5 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `body` )
        ( `pf5` ) ) ).
    cl_abap_unit_assert=>assert_true(
      act = line_exists( ls_result-status-active_pf_keys[ table_line = 5 ] ) ).
  ENDMETHOD.

  METHOD runtime_authorizes_pf_keys.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_049( ) ).

    DATA(ls_disabled) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_pf
      pf_key     = 6 ) ).
    cl_abap_unit_assert=>assert_false( ls_disabled-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_disabled-error
      exp = 'PF key is not active for the current host page' ).

    DATA(ls_allowed) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_pf
      pf_key     = 5 ) ).
    cl_abap_unit_assert=>assert_true( ls_allowed-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_allowed-compatibility-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `body` )
        ( `pf5` ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
