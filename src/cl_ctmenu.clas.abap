CLASS cl_ctmenu DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS hide_functions
      IMPORTING
        fcodes TYPE ui_functions.

    METHODS add_function
      IMPORTING
        fcode TYPE ui_func
        text  TYPE gui_text.
ENDCLASS.

CLASS cl_ctmenu IMPLEMENTATION.

  METHOD add_function.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hide_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.