CLASS cl_salv_form_uie_text_view DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie.
  PUBLIC SECTION.

    METHODS set_text
      IMPORTING
        value TYPE any.

    METHODS get_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_tooltip
      IMPORTING
        value TYPE any.

    METHODS get_tooltip
      RETURNING
        VALUE(value) TYPE string.

ENDCLASS.

CLASS cl_salv_form_uie_text_view IMPLEMENTATION.

  METHOD set_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_tooltip.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_tooltip.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
