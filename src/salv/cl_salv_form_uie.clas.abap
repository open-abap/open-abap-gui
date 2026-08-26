CLASS cl_salv_form_uie DEFINITION PUBLIC INHERITING FROM cl_salv_form_element.
  PUBLIC SECTION.

    METHODS set_layout_data
      IMPORTING
        value TYPE REF TO cl_salv_form_layout_data.

    METHODS get_layout_data
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_form_layout_data.

ENDCLASS.

CLASS cl_salv_form_uie IMPLEMENTATION.

  METHOD set_layout_data.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_layout_data.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
