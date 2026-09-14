CLASS cl_salv_column_tree DEFINITION PUBLIC INHERITING FROM cl_salv_column.
  PUBLIC SECTION.

    METHODS set_icon
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_icon
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_icon TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_column_tree IMPLEMENTATION.

  METHOD set_icon.
    mv_icon = value.
  ENDMETHOD.

  METHOD is_icon.
    value = mv_icon.
  ENDMETHOD.

ENDCLASS.
