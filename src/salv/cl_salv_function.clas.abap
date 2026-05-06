CLASS cl_salv_function DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS get_name
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_visible
      IMPORTING
        value TYPE abap_bool.
ENDCLASS.

CLASS cl_salv_function IMPLEMENTATION.
  METHOD set_visible.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_name.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
