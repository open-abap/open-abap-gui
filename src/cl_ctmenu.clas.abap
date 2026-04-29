CLASS cl_ctmenu DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS hide_functions
      IMPORTING
        fcodes TYPE ui_functions.

    METHODS add_function
      IMPORTING
        fcode    TYPE ui_func
        text     TYPE gui_text
        disabled TYPE abap_bool OPTIONAL.

    METHODS add_separator.

    METHODS clear.

    METHODS add_submenu
      IMPORTING
        menu        TYPE REF TO cl_ctmenu
        text        TYPE gui_text
        icon        TYPE icon_d OPTIONAL
        disabled    TYPE any OPTIONAL
        hidden      TYPE any OPTIONAL
        accelerator TYPE any OPTIONAL.
ENDCLASS.

CLASS cl_ctmenu IMPLEMENTATION.
  METHOD add_submenu.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD clear.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_separator.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_function.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hide_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.