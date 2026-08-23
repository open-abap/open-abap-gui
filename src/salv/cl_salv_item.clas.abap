CLASS cl_salv_item DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS set_type
      IMPORTING
        value TYPE i.

    METHODS get_type
      RETURNING
        VALUE(value) TYPE i.

    METHODS set_text
      IMPORTING
        value TYPE clike.

    METHODS set_icon
      IMPORTING
        value TYPE any.

ENDCLASS.

CLASS cl_salv_item IMPLEMENTATION.

  METHOD set_type.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_type.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_icon.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
