CLASS cl_salv_item DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS set_type
      IMPORTING
        value TYPE i.

    METHODS get_type
      RETURNING
        VALUE(value) TYPE i.

    METHODS get_value
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_value
      IMPORTING
        value TYPE clike.

    METHODS set_icon
      IMPORTING
        value TYPE any.

    METHODS get_icon
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_style
      IMPORTING
        value TYPE i.

    METHODS get_style
      RETURNING
        VALUE(value) TYPE i.

    METHODS set_editable
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_editable
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_checked
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_checked
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_type TYPE i.
    DATA mv_text TYPE string.
    DATA mv_icon TYPE string.
    DATA mv_style TYPE i.
    DATA mv_editable TYPE abap_bool.
    DATA mv_checked TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_item IMPLEMENTATION.

  METHOD set_type.
    mv_type = value.
  ENDMETHOD.

  METHOD get_type.
    value = mv_type.
  ENDMETHOD.

  METHOD get_value.
    value = mv_text.
  ENDMETHOD.

  METHOD set_value.
    mv_text = value.
  ENDMETHOD.

  METHOD set_icon.
    mv_icon = value.
  ENDMETHOD.

  METHOD get_icon.
    value = mv_icon.
  ENDMETHOD.

  METHOD set_style.
    mv_style = value.
  ENDMETHOD.

  METHOD get_style.
    value = mv_style.
  ENDMETHOD.

  METHOD set_editable.
    mv_editable = value.
  ENDMETHOD.

  METHOD is_editable.
    value = mv_editable.
  ENDMETHOD.

  METHOD set_checked.
    mv_checked = value.
  ENDMETHOD.

  METHOD is_checked.
    value = mv_checked.
  ENDMETHOD.

ENDCLASS.
