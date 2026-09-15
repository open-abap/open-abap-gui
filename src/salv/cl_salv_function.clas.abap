CLASS cl_salv_function DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS get_name
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_name
      IMPORTING
        value TYPE clike.

    METHODS set_icon
      IMPORTING
        value TYPE clike.

    METHODS get_icon
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_text
      IMPORTING
        value TYPE clike.

    METHODS get_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_tooltip
      IMPORTING
        value TYPE clike.

    METHODS get_tooltip
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_visible
      IMPORTING
        value TYPE abap_bool.

    METHODS get_visible
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_name TYPE string.
    DATA mv_icon TYPE string.
    DATA mv_text TYPE string.
    DATA mv_tooltip TYPE string.
    DATA mv_visible TYPE abap_bool.
ENDCLASS.

CLASS cl_salv_function IMPLEMENTATION.
  METHOD set_visible.
    mv_visible = value.
  ENDMETHOD.

  METHOD get_name.
    value = mv_name.
  ENDMETHOD.

  METHOD set_name.
    mv_name = CONV string( value ).
  ENDMETHOD.

  METHOD set_icon.
    mv_icon = CONV string( value ).
  ENDMETHOD.

  METHOD get_icon.
    value = mv_icon.
  ENDMETHOD.

  METHOD set_text.
    mv_text = CONV string( value ).
  ENDMETHOD.

  METHOD get_text.
    value = mv_text.
  ENDMETHOD.

  METHOD set_tooltip.
    mv_tooltip = CONV string( value ).
  ENDMETHOD.

  METHOD get_tooltip.
    value = mv_tooltip.
  ENDMETHOD.

  METHOD get_visible.
    value = mv_visible.
  ENDMETHOD.

ENDCLASS.
