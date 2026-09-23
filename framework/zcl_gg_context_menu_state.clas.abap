CLASS zcl_gg_context_menu_state DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_item,
             fcode     TYPE string,
             text      TYPE string,
             icon      TYPE string,
             disabled  TYPE abap_bool,
             hidden    TYPE abap_bool,
             separator TYPE abap_bool,
             submenu   TYPE REF TO object,
           END OF ty_item.
    TYPES ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

    CLASS-METHODS get_items
      IMPORTING
        io_menu         TYPE REF TO object
      RETURNING
        VALUE(rt_items) TYPE ty_items.

    CLASS-METHODS set_items
      IMPORTING
        io_menu  TYPE REF TO object
        it_items TYPE ty_items.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_state,
             menu  TYPE REF TO object,
             items TYPE ty_items,
           END OF ty_state.
    TYPES ty_states TYPE STANDARD TABLE OF ty_state WITH DEFAULT KEY.

    CLASS-DATA mt_states TYPE ty_states.
ENDCLASS.

CLASS zcl_gg_context_menu_state IMPLEMENTATION.
  METHOD get_items.
    LOOP AT mt_states INTO DATA(ls_state).
      IF ls_state-menu = io_menu.
        rt_items = ls_state-items.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_items.
    LOOP AT mt_states ASSIGNING FIELD-SYMBOL(<ls_state>).
      IF <ls_state>-menu = io_menu.
        <ls_state>-items = it_items.
        RETURN.
      ENDIF.
    ENDLOOP.
    APPEND VALUE #( menu = io_menu items = it_items ) TO mt_states.
  ENDMETHOD.
ENDCLASS.
