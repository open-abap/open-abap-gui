CLASS ltcl_gg_workbench_utility DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_styles FOR TESTING.
    METHODS renders_top FOR TESTING.
    METHODS renders_status_owned_icon_bar FOR TESTING.
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

  METHOD renders_status_owned_icon_bar.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_top(
      iv_runtime = abap_true
      is_status  = VALUE #( active_ucomm   = VALUE #( ( 'RUN' ) ( 'EXCLUDED' ) )
                            excluded_ucomm = VALUE #( ( 'EXCLUDED' ) )
                            icon_bar       = VALUE #(
                              ( ucomm = 'RUN'      label = `A & <Run>` icon = `not-a-real-icon` )
                              ( ucomm = 'INACTIVE' label = `Inactive` icon = `refresh` )
                              ( ucomm = 'EXCLUDED' label = `Excluded` icon = `refresh` separator = abap_true ) ) ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'title="A &amp; &lt;Run&gt;"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'value="COMMAND:RUN"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'value="COMMAND:INACTIVE"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'value="COMMAND:EXCLUDED"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-ucomm="INACTIVE" disabled' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-toolbar-separator' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '#wb-icon-help-circle' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'not-a-real-icon' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<svg on' ) ).
  ENDMETHOD.

  METHOD renders_top.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_top( ).
    DATA(lv_custom_html) = zcl_gg_workbench_utility=>render_top( iv_title = `<Example & title>` ).
    DATA(lv_untrusted_html) = zcl_gg_workbench_utility=>render_top( iv_title = `</h1><style>.wb-appbar{display:none}</style>` ).
    DATA(lv_icon_html) = zcl_gg_workbench_utility=>render_top(
      is_status = VALUE #( icon_bar = VALUE #( ( label = `Refresh` icon = `refresh` ) ) ) ).
    DATA(lv_dynpro_html) = zcl_gg_workbench_utility=>render_top(
      iv_title        = `Dynpro`
      iv_content_form = `gg-dynpro-form`
      is_status       = VALUE #( status = `STATUS` ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-menubar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-commandbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-appbar' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'wb-toolbar' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'wb-toolbar-button' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'Create' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'Add to favorites' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'title="Refresh"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_icon_html CS 'title="Refresh"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_icon_html CS 'wb-icon-refresh' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Workbench</h1>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_custom_html CS '&lt;Example &amp; title&gt;</h1>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_untrusted_html CS '&lt;/h1&gt;&lt;style&gt;.wb-appbar{display:none}&lt;/style&gt;' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_untrusted_html CS '</h1><style>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '<span class="wb-brand">open-abap</span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '>Applications</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '>Dynpro</h1>' ) ).
* The app bar shows the title only, so the CUA status name never reaches the page.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '>Dynpro</h1></header>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_dynpro_html CS 'STATUS' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_dynpro_html CS 'wb-appbar--dynpro' ) ).
  ENDMETHOD.

  METHOD renders_bottom.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_bottom( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-statusbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-status-feedback' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'event.key!=="F3"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-command-button--back:not(:disabled)' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<script>' ) ).
  ENDMETHOD.

ENDCLASS.
