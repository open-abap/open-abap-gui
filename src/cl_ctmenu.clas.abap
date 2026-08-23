CLASS cl_ctmenu DEFINITION PUBLIC.
  PUBLIC SECTION.

    DATA default_function TYPE ui_func READ-ONLY.

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
ENDCLASS.

CLASS cl_ctmenu IMPLEMENTATION.
  METHOD add_submenu.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_menu.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD clear.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD reset.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_separator.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_function.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD modify_function_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_default_function.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hide_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD show_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD disable_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD enable_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD load_gui_status.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
