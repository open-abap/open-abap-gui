CLASS cl_salv_form_uie_layout_grid DEFINITION PUBLIC INHERITING FROM cl_salv_form_element.
  PUBLIC SECTION.
    METHODS add_row
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_form_layout_flow.
ENDCLASS.

CLASS cl_salv_form_uie_layout_grid IMPLEMENTATION.

  METHOD add_row.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.