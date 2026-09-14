CLASS cl_salv_column_list DEFINITION PUBLIC INHERITING FROM cl_salv_column.
  PUBLIC SECTION.
    METHODS set_icon
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_cell_type
      IMPORTING
        value TYPE any OPTIONAL.

    METHODS set_key
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_color
      IMPORTING
        value TYPE lvc_s_colo.

    METHODS set_f4
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_icon
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS get_cell_type
      RETURNING
        VALUE(value) TYPE i.

    METHODS is_key
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS get_color
      RETURNING
        VALUE(value) TYPE lvc_s_colo.

    METHODS has_f4
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_icon TYPE abap_bool.
    DATA mv_cell_type TYPE i.
    DATA mv_key TYPE abap_bool.
    DATA ms_color TYPE lvc_s_colo.
    DATA mv_f4 TYPE abap_bool.
ENDCLASS.

CLASS cl_salv_column_list IMPLEMENTATION.
  METHOD set_color.
    ms_color = value.
  ENDMETHOD.

  METHOD set_f4.
    mv_f4 = value.
  ENDMETHOD.

  METHOD set_key.
    mv_key = value.
  ENDMETHOD.

  METHOD set_cell_type.
    mv_cell_type = CONV i( value ).
  ENDMETHOD.

  METHOD set_icon.
    mv_icon = value.
  ENDMETHOD.

  METHOD is_icon.
    value = mv_icon.
  ENDMETHOD.

  METHOD get_cell_type.
    value = mv_cell_type.
  ENDMETHOD.

  METHOD is_key.
    value = mv_key.
  ENDMETHOD.

  METHOD get_color.
    value = ms_color.
  ENDMETHOD.

  METHOD has_f4.
    value = mv_f4.
  ENDMETHOD.
ENDCLASS.
