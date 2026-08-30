CLASS ltcl_gg_workbench_utility DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_styles FOR TESTING.
    METHODS renders_top FOR TESTING.
    METHODS renders_bottom FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_workbench_utility IMPLEMENTATION.

  METHOD renders_styles.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_styles( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-menubar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-statusbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-runtime-content' ) ).
* A disabled command must not react to hover or to being pressed.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-command-button:not(:disabled):active' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '.wb-command-button:active' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-command-button:disabled:active' ) ).
  ENDMETHOD.

  METHOD renders_top.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_top( ).
    DATA(lv_custom_html) = zcl_gg_workbench_utility=>render_top( iv_title = `<Example & title>` ).
    DATA(lv_icon_html) = zcl_gg_workbench_utility=>render_top(
      it_icon_bar = VALUE #( ( label = `Refresh` icon = `refresh` ) ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-menubar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-commandbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-appbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-toolbar' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'title="Refresh"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_icon_html CS 'title="Refresh"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_icon_html CS 'wb-icon-refresh' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Workbench</span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_custom_html CS '&lt;Example &amp; title&gt;</span>' ) ).
  ENDMETHOD.

  METHOD renders_bottom.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_bottom( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-statusbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-status-feedback' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<script>' ) ).
  ENDMETHOD.

ENDCLASS.
