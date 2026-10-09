CLASS lcl_toolbar_event_handler DEFINITION.
  PUBLIC SECTION.
    DATA selected TYPE string.
    DATA dropdown TYPE string.
    DATA dropdown_x TYPE i.
    DATA dropdown_y TYPE i.
    METHODS on_selected
      FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING
        fcode.
    METHODS on_dropdown
      FOR EVENT dropdown_clicked OF cl_gui_toolbar
      IMPORTING
        fcode
        posx
        posy.
ENDCLASS.

CLASS lcl_toolbar_event_handler IMPLEMENTATION.
  METHOD on_selected.
    selected = fcode.
  ENDMETHOD.

  METHOD on_dropdown.
    dropdown = fcode.
    dropdown_x = posx.
    dropdown_y = posy.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_gui_toolbar DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS updates_button_state FOR TESTING.
    METHODS renders_menus_and_events FOR TESTING.
    METHODS renders_toolbar_overflow FOR TESTING.
ENDCLASS.

CLASS cl_gui_toolbar DEFINITION LOCAL FRIENDS ltcl_gui_toolbar.

CLASS ltcl_gui_toolbar IMPLEMENTATION.
  METHOD updates_button_state.
    zcl_gg_gui_runtime=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'TOOLBAR_TEST' ).
    DATA(lo_toolbar) = NEW cl_gui_toolbar( parent = lo_container ).
    lo_toolbar->add_button(
      fcode     = 'TEST'
      icon      = '@'
      butn_type = 0
      text      = 'Test'
      quickinfo = 'Test button' ).
    lo_toolbar->set_button_state(
      fcode   = 'TEST'
      enabled = ' '
      checked = 'X' ).
    lo_toolbar->set_button_info(
      fcode     = 'TEST'
      text      = 'Updated'
      quickinfo = 'Updated button' ).
    DATA(lv_toolbar_html) = zcl_gg_gui_runtime=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_toolbar_html CS '|FUNCTION|TEST"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_toolbar_html CS '>Updated</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_toolbar_html CS 'aria-pressed="true"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_toolbar_html CS 'disabled aria-disabled="true"' ) ).
    lo_toolbar->set_button_visible(
      fcode   = 'TEST'
      visible = ' ' ).
    lv_toolbar_html = zcl_gg_gui_runtime=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_toolbar_html CS '|FUNCTION|TEST' ) ).
    zcl_gg_gui_runtime=>clear( ).
  ENDMETHOD.

  METHOD renders_menus_and_events.
    zcl_gg_gui_runtime=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'TOOLBAR-MENU' ).
    DATA(lo_toolbar) = NEW cl_gui_toolbar( parent = lo_container ).
    lo_toolbar->add_button(
      fcode     = 'RUN'
      icon      = '@'
      butn_type = 0
      text      = 'Run'
      quickinfo = 'Run action' ).
    lo_toolbar->add_button(
      fcode     = 'MENU'
      icon      = '@'
      butn_type = 1
      text      = 'More'
      quickinfo = 'More actions' ).
    DATA(lo_menu) = NEW cl_ctmenu( ).
    lo_menu->add_function( fcode = 'MENU-RUN'
                           text  = 'Menu run' ).
    lo_menu->add_separator( ).
    lo_menu->add_function( fcode    = 'MENU-OFF'
                           text     = 'Unavailable'
                           disabled = abap_true ).
    lo_toolbar->set_static_ctxmenu( fcode   = 'MENU'
                                    ctxmenu = lo_menu
                                    btntype = 1 ).
    DATA(lo_handler) = NEW lcl_toolbar_event_handler( ).
    SET HANDLER lo_handler->on_selected FOR lo_toolbar.
    SET HANDLER lo_handler->on_dropdown FOR lo_toolbar.
    lo_toolbar->press_button( 'RUN' ).
    lo_toolbar->press_button( 'MENU-OFF' ).
    lo_toolbar->press_dropdown( fcode = 'MENU'
                                posx  = 12
                                posy  = 34 ).
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_handler->selected
      exp = 'RUN' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_handler->dropdown
      exp = 'MENU' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_handler->dropdown_x
      exp = 12 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_handler->dropdown_y
      exp = 34 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-toolbar-menu' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Menu run' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<details class="gg-toolbar-dropdown"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Unavailable' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'disabled aria-disabled="true"' ) ).
    zcl_gg_gui_runtime=>clear( ).
  ENDMETHOD.

  METHOD renders_toolbar_overflow.
    zcl_gg_gui_runtime=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'TOOLBAR-OVERFLOW' ).
    DATA(lo_toolbar) = NEW cl_gui_toolbar( parent = lo_container ).
    DO 7 TIMES.
      lo_toolbar->add_button(
        fcode     = |B{ sy-index }|
        icon      = '@'
        butn_type = 0
        text      = |Button { sy-index }|
        quickinfo = |Button { sy-index }| ).
    ENDDO.
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-toolbar-overflow' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'More toolbar actions' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-keyshortcuts="Enter"' ) ).
    zcl_gg_gui_runtime=>clear( ).
  ENDMETHOD.
ENDCLASS.
