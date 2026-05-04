CLASS cl_salv_functions DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS add_function
        IMPORTING
        name     TYPE any
        icon     TYPE string OPTIONAL
        text     TYPE string OPTIONAL
        tooltip  TYPE string
        position TYPE any.

    METHODS set_all
      IMPORTING
        flag TYPE abap_bool OPTIONAL.
ENDCLASS.

CLASS cl_salv_functions IMPLEMENTATION.
  METHOD set_all.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_function.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.