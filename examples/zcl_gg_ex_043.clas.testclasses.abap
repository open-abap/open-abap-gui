CLASS ltcl_ex_43 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS selects_hidden_line FOR TESTING.
    METHODS renders_accessible_list FOR TESTING.
    METHODS list_model_and_token FOR TESTING.
    METHODS renders_hidden_field FOR TESTING.
    METHODS runtime_history_back FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_43 IMPLEMENTATION.

  METHOD selects_hidden_line.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report     = NEW zcl_gg_ex_043( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `1` )
        ( `2` )
        ( `3` )
        ( `2` ) ) ).
  ENDMETHOD.

  METHOD renders_accessible_list.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_043( ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<form method="post" action="/dispatch">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'aria-label="Select line 1"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-action-token="' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'data-hide-value' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'name="GV_ID"' ) ).
  ENDMETHOD.

  METHOD list_model_and_token.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_043( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-model_events[ 1 ]-kind
      exp = 'PAGE_BEGIN' ).
    cl_abap_unit_assert=>assert_not_initial( ls_result-render_lines[ 1 ]-token ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-action-token=' ) ).

    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_043( ) ).
    DATA(ls_invalid) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_line
      row        = 1
      token      = 'wrong' ) ).
    cl_abap_unit_assert=>assert_false( ls_invalid-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD renders_hidden_field.
    DATA(ls_hidden) = zcl_gg_host=>run( NEW zcl_gg_ex_043( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_hidden-render_lines[ 1 ]-fields[ name = 'GV_ID' ]-value
      exp = '1' ).
  ENDMETHOD.

  METHOD runtime_history_back.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_043( ) ).
    cl_abap_unit_assert=>assert_not_initial( ls_start-compatibility-lines ).
    DATA(ls_detail) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_line
      row        = 1
      token      = 'H-1-1' ) ).
    cl_abap_unit_assert=>assert_true( ls_detail-valid ).
    DATA(ls_back) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_detail-session_id
      page_id    = ls_detail-page_id
      action     = zif_gg_host_html_v1=>action_back ) ).
    cl_abap_unit_assert=>assert_true( ls_back-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-page_id
                                        exp = ls_start-page_id ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_back-pages )
                                        exp = 2 ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
