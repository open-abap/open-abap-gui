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

    METHODS set_style
      IMPORTING
        value TYPE i.

    METHODS set_editable
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_checked
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_checked
      RETURNING
        VALUE(value) TYPE abap_bool.

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

  METHOD set_style.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_editable.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_checked.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD is_checked.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
