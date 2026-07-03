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
ENDCLASS.

CLASS cl_gui_ilidragndrop_control IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD start_dragging.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD show.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hide.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_contextmenuitem.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD show_contextmenu.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hide_contextmenu.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD clear_contextmenu.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
