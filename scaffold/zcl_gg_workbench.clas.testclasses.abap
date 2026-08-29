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
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'ZCL_GG_EX_01' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'ZCL_GG_INTEGRATION_DYNPRO' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-commandbar"' ) ).
  ENDMETHOD.

ENDCLASS.
