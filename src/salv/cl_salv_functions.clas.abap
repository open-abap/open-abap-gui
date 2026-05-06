CLASS cl_salv_functions DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS add_function
        IMPORTING
        name     TYPE any
        icon     TYPE any OPTIONAL
        text     TYPE any OPTIONAL
        tooltip  TYPE any
        position TYPE any.

    METHODS set_all
      IMPORTING
        flag TYPE abap_bool OPTIONAL.

    METHODS get_functions
      RETURNING
        VALUE(function_list) TYPE salv_t_ui_func.
ENDCLASS.

CLASS cl_salv_functions IMPLEMENTATION.
  METHOD get_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_all.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_function.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.