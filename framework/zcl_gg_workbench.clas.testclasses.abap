CLASS ltcl_gg_workbench DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_raw_html FOR TESTING.
    METHODS renders_exception_in_shell FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_workbench IMPLEMENTATION.

  METHOD renders_raw_html.
    DATA lo_html TYPE REF TO zif_gg_raw_html_v1.

    lo_html = NEW zcl_gg_workbench( ).
    DATA(lv_html) = lo_html->get_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<!doctype html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-app-list"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<details' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'role="tree"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'href="/ZCL_' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '</aside><div class="wb-splitter" role="separator" aria-orientation="vertical"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-controls="wb-app-panel"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-commandbar"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '/converter/preview' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-logo-mark" viewBox="0 0 108 108"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'stop-color="#174a80"' ) ).

    DATA(lv_error_html) = zcl_gg_workbench=>render_error( iv_error = `Unknown <transaction> & code` ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error_html CS 'wb-status-error' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error_html CS 'Unknown &lt;transaction&gt; &amp; code' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error_html CS 'aria-live="assertive"' ) ).
*   The rejected command is reported, never echoed back into the command field.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error_html CS 'id="wb-command" name="command" type="text" placeholder="Command" autocomplete="off" value=""' ) ).
  ENDMETHOD.

  METHOD renders_exception_in_shell.
    DATA(lx_error) = NEW cx_sy_dyn_call_illegal_func( function = '<Z_FUNC>' ).

    DATA(lv_html) = zcl_gg_workbench=>render_exception( lx_error ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-commandbar"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-page-kind="ERROR"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      lv_html CS '<pre class="gg-list gg-exception">Unhandled exception CX_SY_DYN_CALL_ILLEGAL_FUNC' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'FUNCTION = &lt;Z_FUNC&gt;</pre>' ) ).
*   No program runs any more, so Back returns to the workbench.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="Return to workbench"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<form id="wb-command-workbench" method="get" action="/" hidden>' ) ).
*   The details are the page; the status bar stays empty.
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      lv_html CS '<span id="wb-status-message" class="wb-status-feedback" aria-live="polite"></span>' ) ).
  ENDMETHOD.

ENDCLASS.
