CLASS cl_ctmenu DEFINITION PUBLIC.
  PUBLIC SECTION.

    TYPES: BEGIN OF ty_item,
             fcode     TYPE string,
             text      TYPE string,
             icon      TYPE string,
             disabled  TYPE abap_bool,
             hidden    TYPE abap_bool,
             separator TYPE abap_bool,
             submenu   TYPE REF TO cl_ctmenu,
           END OF ty_item.
    TYPES ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

    DATA default_function TYPE ui_func READ-ONLY.

    METHODS get_items
      RETURNING
        VALUE(items) TYPE ty_items.

    METHODS hide_functions
      IMPORTING
        fcodes TYPE ui_functions.

    METHODS show_functions
      IMPORTING
        fcodes TYPE ui_functions.

    METHODS disable_functions
      IMPORTING
        fcodes TYPE ui_functions.

    METHODS enable_functions
      IMPORTING
        fcodes TYPE ui_functions.

    METHODS add_function
      IMPORTING
        fcode             TYPE ui_func
        text              TYPE gui_text
        icon              TYPE icon_d OPTIONAL
        ftype             TYPE cua_ftyp OPTIONAL
        checked           TYPE abap_bool OPTIONAL
        hidden            TYPE abap_bool OPTIONAL
        accelerator       TYPE cua_path OPTIONAL
        disabled          TYPE abap_bool OPTIONAL
        insert_at_the_top TYPE abap_bool OPTIONAL.

    METHODS modify_function_text
      IMPORTING
        fcode       TYPE ui_func
        text        TYPE gui_text OPTIONAL
        accelerator TYPE cua_path OPTIONAL.

    METHODS set_default_function
      IMPORTING
        fcode TYPE ui_func.

    METHODS add_separator.

    METHODS clear.

    METHODS reset.

    METHODS add_menu
      IMPORTING
        menu TYPE REF TO cl_ctmenu.

    METHODS add_submenu
      IMPORTING
        menu        TYPE REF TO cl_ctmenu
        text        TYPE gui_text
        icon        TYPE icon_d OPTIONAL
        disabled    TYPE any OPTIONAL
        hidden      TYPE any OPTIONAL
        accelerator TYPE any OPTIONAL.

    CLASS-METHODS load_gui_status
      IMPORTING
        program TYPE program
        status  TYPE cua_status
        menu    TYPE REF TO cl_ctmenu
        disable TYPE ui_functions OPTIONAL
      EXCEPTIONS
        read_error.

  PRIVATE SECTION.
    DATA mt_items TYPE ty_items.
ENDCLASS.

CLASS cl_ctmenu IMPLEMENTATION.
  METHOD get_items.
    items = mt_items.
  ENDMETHOD.

  METHOD add_submenu.
    APPEND VALUE #( text     = text
                    icon     = icon
                    disabled = xsdbool( disabled IS NOT INITIAL )
                    hidden   = xsdbool( hidden IS NOT INITIAL )
                    submenu  = menu ) TO mt_items.
  ENDMETHOD.

  METHOD add_menu.
    IF menu IS BOUND.
      APPEND LINES OF menu->get_items( ) TO mt_items.
    ENDIF.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_items.
  ENDMETHOD.

  METHOD reset.
    CLEAR mt_items.
  ENDMETHOD.

  METHOD add_separator.
    APPEND VALUE #( separator = abap_true ) TO mt_items.
  ENDMETHOD.

  METHOD add_function.
    DATA ls_item TYPE ty_item.

    ls_item-fcode = fcode.
    ls_item-text = text.
    ls_item-icon = icon.
    ls_item-disabled = disabled.
    ls_item-hidden = hidden.
    IF insert_at_the_top = abap_true.
      INSERT ls_item INTO mt_items INDEX 1.
    ELSE.
      APPEND ls_item TO mt_items.
    ENDIF.
  ENDMETHOD.

  METHOD modify_function_text.
    LOOP AT mt_items ASSIGNING FIELD-SYMBOL(<ls_item>) WHERE fcode = fcode.
      IF text IS NOT INITIAL.
        <ls_item>-text = text.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_default_function.
    default_function = fcode.
  ENDMETHOD.

  METHOD hide_functions.
    LOOP AT mt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      IF line_exists( fcodes[ table_line = <ls_item>-fcode ] ).
        <ls_item>-hidden = abap_true.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD show_functions.
    LOOP AT mt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      IF line_exists( fcodes[ table_line = <ls_item>-fcode ] ).
        CLEAR <ls_item>-hidden.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD disable_functions.
    LOOP AT mt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      IF line_exists( fcodes[ table_line = <ls_item>-fcode ] ).
        <ls_item>-disabled = abap_true.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD enable_functions.
    LOOP AT mt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      IF line_exists( fcodes[ table_line = <ls_item>-fcode ] ).
        CLEAR <ls_item>-disabled.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD load_gui_status.
    RETURN.
  ENDMETHOD.

ENDCLASS.
