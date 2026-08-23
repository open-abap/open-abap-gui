CLASS cl_dd_select_element DEFINITION PUBLIC INHERITING FROM cl_dd_form_element.
  PUBLIC SECTION.

    EVENTS selected
      EXPORTING
        VALUE(sender) TYPE REF TO cl_dd_select_element.

    METHODS set_value
      IMPORTING
        value TYPE sdydo_value.

ENDCLASS.

CLASS cl_dd_select_element IMPLEMENTATION.
  METHOD set_value.
    RETURN. " todo, implement method
  ENDMETHOD.
ENDCLASS.
