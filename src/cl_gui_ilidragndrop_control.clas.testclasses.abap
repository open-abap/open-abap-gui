CLASS ltcl_gui_ilidragndrop_control DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_honest_fallback FOR TESTING.
ENDCLASS.

CLASS ltcl_gui_ilidragndrop_control IMPLEMENTATION.

  METHOD renders_honest_fallback.
    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'ILI_ROOT' ).
    DATA(lo_dragdrop) = NEW cl_gui_ilidragndrop_control( parent = lo_root ).
    lo_dragdrop->start_dragging( left   = 12
                                 top    = 18
                                 width  = 240
                                 height = 90
                                 mode   = cl_gui_ilidragndrop_control=>co_drag_resize_xy ).
    lo_dragdrop->add_contextmenuitem( str = 'Move' ).
    lo_dragdrop->add_contextmenuitem( str = 'Copy' ).
    lo_dragdrop->show_contextmenu( ).

    DATA(lv_html) = cl_gui_control=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-control-kind="DRAGDROP"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-native-capability="unavailable"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-payload="Legacy ActiveX drag/drop unavailable; geometry=12,18,240,90' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<textarea' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Legacy ActiveX drag/drop is unavailable in the browser.</textarea>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '>Legacy ActiveX drag/drop unavailable; geometry=' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'context-menu=visible; items=2' ) ).

    lo_dragdrop->hide( ).
    lv_html = cl_gui_control=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-control-kind="DRAGDROP"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS ' hidden' ) ).

    lo_dragdrop->clear_contextmenu( ).
    lv_html = cl_gui_control=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'context-menu=cleared' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'geometry=12,18,240,90' ) ).
  ENDMETHOD.

ENDCLASS.
