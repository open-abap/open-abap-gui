CLASS cl_salv_form_layout_data_grid DEFINITION PUBLIC INHERITING FROM cl_salv_form_layout_data.
  PUBLIC SECTION.

    METHODS set_h_align
      IMPORTING
        value TYPE i.

    METHODS get_h_align
      RETURNING
        VALUE(value) TYPE i.
  PRIVATE SECTION.
    DATA mv_h_align TYPE i.

ENDCLASS.

CLASS cl_salv_form_layout_data_grid IMPLEMENTATION.

  METHOD set_h_align.
    mv_h_align = value.
  ENDMETHOD.

  METHOD get_h_align.
    value = mv_h_align.
  ENDMETHOD.

ENDCLASS.
