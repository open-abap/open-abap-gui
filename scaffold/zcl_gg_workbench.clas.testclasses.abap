CLASS ltcl_gg_workbench DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_raw_html FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_workbench IMPLEMENTATION.

  METHOD renders_raw_html.
    DATA lo_html TYPE REF TO zif_gg_raw_html_v1.

    lo_html = NEW zcl_gg_workbench( ).
    DATA(lv_html) = lo_html->get_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<!doctype html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'ZGG_EX_01' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'WRITE literal' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '/transaction?tcode=ZGG_EX_01' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-app-list"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<details' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'role="tree"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '/ZCL_GG_EX_01' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-commandbar"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-logo-mark" viewBox="0 0 108 108"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'stop-color="#174a80"' ) ).

    DATA(lv_error_html) = zcl_gg_workbench=>render_error(
      iv_command = `/nzgg_ex01`
      iv_error = `Unknown <transaction> & code` ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error_html CS 'wb-status-error' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error_html CS 'Unknown &lt;transaction&gt; &amp; code' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error_html CS 'aria-live="assertive"' ) ).
  ENDMETHOD.

ENDCLASS.
