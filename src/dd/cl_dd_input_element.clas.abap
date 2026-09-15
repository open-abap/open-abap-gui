CLASS cl_dd_input_element DEFINITION PUBLIC INHERITING FROM cl_dd_form_element
  FRIENDS cl_dd_form_area.
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

  PRIVATE SECTION.
    DATA size TYPE i.
    DATA maxlength TYPE i.
    DATA tooltip TYPE string.
    DATA a11y_label TYPE string.
ENDCLASS.

CLASS cl_dd_input_element IMPLEMENTATION.
  METHOD set_value.
    me->value = value.
    RAISE EVENT entered EXPORTING sender = me.
  ENDMETHOD.

ENDCLASS.
