CLASS ltcl_gg_analytics_cockpit_base DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS selection_screen FOR TESTING.
    METHODS composite_controls FOR TESTING.
    METHODS save_filters FOR TESTING.
    METHODS open_detail FOR TESTING.
    METHODS hostile_filter_text FOR TESTING.
    METHODS rejects_undeclared_command FOR TESTING.
ENDCLASS.

CLASS ltcl_gg_analytics_cockpit_base IMPLEMENTATION.

  METHOD selection_screen.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_response) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_150( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_response-page_kind exp = 'SELECTION' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'P_CARR' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD composite_controls.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_150( ) ).
    DATA(ls_response) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_submit
      ucomm = 'ONLI'
      values = VALUE #( ( name = 'P_CARR' value = 'Lufthansa' )
                        ( name = 'P_DATE' value = '20260830' ) ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_response-page_kind exp = 'LIST' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'Analytics cockpit' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'data-control-kind="ALV_GRID"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'data-control-kind="SIMPLE_TREE"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'data-control-kind="CHART_ENGINE"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'Detail dynpro pane' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD save_filters.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_150( ) ).
    DATA(ls_list) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_submit
      ucomm = 'ONLI'
      values = VALUE #( ( name = 'P_CARR' value = 'Lufthansa' )
                        ( name = 'P_DATE' value = '20260830' ) ) ) ).
    DATA(ls_response) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_list-session_id
      page_id = ls_list-page_id
      action = zif_gg_host_html_v1=>action_command
      ucomm = 'SAVE_FILTERS' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'filters saved' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD open_detail.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_150( ) ).
    DATA(ls_list) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_submit
      ucomm = 'ONLI'
      values = VALUE #( ( name = 'P_CARR' value = 'United' )
                        ( name = 'P_DATE' value = '20260830' ) ) ) ).
    DATA(ls_response) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_list-session_id
      page_id = ls_list-page_id
      action = zif_gg_host_html_v1=>action_command
      ucomm = 'OPEN_DETAIL' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS 'Detail dynpro opened' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD hostile_filter_text.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_150( ) ).
    DATA(ls_response) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_submit
      ucomm = 'ONLI'
      values = VALUE #( ( name = 'P_CARR' value = `"><script>alert(1)</script>` )
                        ( name = 'P_DATE' value = '20260830' ) ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_response-html CS '&lt;script&gt;' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_response-html CS '<script>alert(1)</script>' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD rejects_undeclared_command.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_150( )
      iv_ucomm  = 'FORGED' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( line_exists( ls_result-messages[
        text = 'Undeclared selection command FORGED' ] ) ) ).
  ENDMETHOD.

ENDCLASS.
