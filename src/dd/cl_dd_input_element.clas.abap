CLASS cl_dd_input_element DEFINITION PUBLIC INHERITING FROM cl_dd_form_element.
  PUBLIC SECTION.

    DATA value TYPE sdydo_value.

    EVENTS entered
      EXPORTING
        VALUE(sender) TYPE REF TO cl_dd_input_element.

    EVENTS help_f1
      EXPORTING
        VALUE(sender) TYPE REF TO cl_dd_input_element.

    METHODS set_value
      IMPORTING
        value TYPE sdydo_value OPTIONAL.
ENDCLASS.

CLASS cl_dd_input_element IMPLEMENTATION.
  METHOD set_value.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.