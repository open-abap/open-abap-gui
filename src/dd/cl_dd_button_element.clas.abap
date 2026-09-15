CLASS cl_dd_button_element DEFINITION PUBLIC INHERITING FROM cl_dd_form_element
  FRIENDS cl_dd_form_area.
  PUBLIC SECTION.

    EVENTS clicked
      EXPORTING
        VALUE(sender) TYPE REF TO cl_dd_button_element.

  PRIVATE SECTION.
    DATA label TYPE string.
    DATA tooltip TYPE string.
    DATA a11y_label TYPE string.

ENDCLASS.

CLASS cl_dd_button_element IMPLEMENTATION.

ENDCLASS.
