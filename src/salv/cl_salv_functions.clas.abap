CLASS cl_salv_functions DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS add_function
        IMPORTING
        name     TYPE any
        icon     TYPE any OPTIONAL
        text     TYPE any OPTIONAL
        tooltip  TYPE any
        position TYPE any.

    METHODS set_function
      IMPORTING
        name    TYPE salv_de_function
        boolean TYPE abap_bool
      RAISING
        cx_salv_not_found
        cx_salv_wrong_call.

    METHODS set_all
      IMPORTING
        flag TYPE abap_bool OPTIONAL.

    METHODS get_functions
      RETURNING
        VALUE(function_list) TYPE salv_t_ui_func.

    METHODS remove_function
      IMPORTING
        name TYPE salv_de_function
      RAISING
        cx_salv_not_found
        cx_salv_wrong_call.

ENDCLASS.

CLASS cl_salv_functions IMPLEMENTATION.
  METHOD set_function.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD remove_function.
    RETURN. " todo, implement method
  ENDMETHOD.

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