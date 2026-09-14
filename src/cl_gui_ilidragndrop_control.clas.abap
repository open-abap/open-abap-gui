CLASS cl_gui_ilidragndrop_control DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS co_nothing TYPE i VALUE -1.
    CONSTANTS co_resize_x TYPE i VALUE 1.
    CONSTANTS co_resize_y TYPE i VALUE 2.
    CONSTANTS co_resize_xy TYPE i VALUE 3.
    CONSTANTS co_drag TYPE i VALUE 4.
    CONSTANTS co_drag_resize_x TYPE i VALUE 5.
    CONSTANTS co_drag_resize_y TYPE i VALUE 6.
    CONSTANTS co_drag_resize_xy TYPE i VALUE 7.

    CONSTANTS co_mf_enabled TYPE i VALUE 0.
    CONSTANTS co_mf_grayed TYPE i VALUE 1.
    CONSTANTS co_mf_disabled TYPE i VALUE 2.
    CONSTANTS co_mf_checked TYPE i VALUE 8.
    CONSTANTS co_mf_unchecked TYPE i VALUE 0.
    CONSTANTS co_mf_separator TYPE i VALUE 2048.

    CONSTANTS mf_enabled TYPE i VALUE 0.
    CONSTANTS mf_grayed TYPE i VALUE 1.
    CONSTANTS mf_disabled TYPE i VALUE 2.
    CONSTANTS mf_checked TYPE i VALUE 8.
    CONSTANTS mf_unchecked TYPE i VALUE 0.
    CONSTANTS mf_separator TYPE i VALUE 2048.

    CONSTANTS event_dropped TYPE i VALUE 1.
    CONSTANTS event_resized TYPE i VALUE 2.
    CONSTANTS event_contextmenurequest TYPE i VALUE 14.

    METHODS constructor
      IMPORTING
        parent                   TYPE REF TO cl_gui_container OPTIONAL
        shellstyle               TYPE i OPTIONAL
        lifetime                 TYPE i OPTIONAL
        atomwidth                TYPE i OPTIONAL
        atomheight               TYPE i OPTIONAL
        atomoffsetx              TYPE i OPTIONAL
        atomoffsety              TYPE i OPTIONAL
        repid                    TYPE c OPTIONAL
        dynnr                    TYPE c OPTIONAL
        disable_list_scrolling   TYPE c OPTIONAL
        manual_scaling           TYPE c OPTIONAL
        register_as_systemevents TYPE c OPTIONAL
        use_internal_contextmenu TYPE c DEFAULT 'X'
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS start_dragging
      IMPORTING
        left   TYPE i
        top    TYPE i
        width  TYPE i
        height TYPE i
        mode   TYPE i
        flush  TYPE c OPTIONAL.

    METHODS show.

    METHODS hide.

    METHODS add_contextmenuitem
      IMPORTING
        str      TYPE c
        menumode TYPE i DEFAULT 0.

    METHODS show_contextmenu.

    METHODS hide_contextmenu.

    METHODS clear_contextmenu.

    EVENTS dropped
      EXPORTING
        VALUE(newleft) TYPE i OPTIONAL
        VALUE(newtop)  TYPE i OPTIONAL.

    EVENTS resized
      EXPORTING
        VALUE(newwidth)  TYPE i OPTIONAL
        VALUE(newheight) TYPE i OPTIONAL.

    EVENTS contextmenu_requested.

    EVENTS contextmenu_clicked
      EXPORTING
        VALUE(no) TYPE i OPTIONAL.

  PRIVATE SECTION.
    DATA mt_context_items TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA mv_context_visible TYPE abap_bool.
    DATA mv_drag_mode TYPE i.
ENDCLASS.

CLASS cl_gui_ilidragndrop_control IMPLEMENTATION.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'DRAGDROP' ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

  METHOD start_dragging.
    mv_drag_mode = mode.
    set_position( left   = left
                  top    = top
                  width  = width
                  height = height ).
    cl_gui_control=>set_payload(
      control = me
      payload = |Legacy ActiveX drag/drop unavailable; geometry={ left },{ top },{ width },{ height }; mode={ mode }| ).
  ENDMETHOD.

  METHOD show.
    set_visible( 'X' ).
    cl_gui_control=>set_payload( control = me
                                 payload = |Legacy ActiveX drag/drop unavailable; visible=true; geometry={ mv_left },{ mv_top },{ mv_width },{ mv_height }; mode={ mv_drag_mode }| ).
  ENDMETHOD.

  METHOD hide.
    set_visible( ' ' ).
    cl_gui_control=>set_payload( control = me
                                 payload = |Legacy ActiveX drag/drop unavailable; visible=false; geometry={ mv_left },{ mv_top },{ mv_width },{ mv_height }; mode={ mv_drag_mode }| ).
  ENDMETHOD.

  METHOD add_contextmenuitem.
    APPEND CONV string( str ) TO mt_context_items.
    cl_gui_control=>set_payload( control = me
                                 payload = |Legacy ActiveX drag/drop unavailable; geometry={ mv_left },{ mv_top },{ mv_width },{ mv_height }; mode={ mv_drag_mode }; context-items={ lines( mt_context_items ) }| ).
  ENDMETHOD.

  METHOD show_contextmenu.
    mv_context_visible = abap_true.
    cl_gui_control=>set_payload( control = me
                                 payload = |Legacy ActiveX drag/drop unavailable; geometry={ mv_left },{ mv_top },{ mv_width },{ mv_height }; mode={ mv_drag_mode }; context-menu=visible; items={ lines( mt_context_items ) }| ).
  ENDMETHOD.

  METHOD hide_contextmenu.
    mv_context_visible = abap_false.
    cl_gui_control=>set_payload( control = me
                                 payload = |Legacy ActiveX drag/drop unavailable; geometry={ mv_left },{ mv_top },{ mv_width },{ mv_height }; mode={ mv_drag_mode }; context-menu=hidden; items={ lines( mt_context_items ) }| ).
  ENDMETHOD.

  METHOD clear_contextmenu.
    CLEAR mt_context_items.
    mv_context_visible = abap_false.
    cl_gui_control=>set_payload( control = me
                                 payload = |Legacy ActiveX drag/drop unavailable; geometry={ mv_left },{ mv_top },{ mv_width },{ mv_height }; mode={ mv_drag_mode }; context-menu=cleared| ).
  ENDMETHOD.

ENDCLASS.
