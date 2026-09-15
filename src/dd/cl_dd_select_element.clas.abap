CLASS cl_dd_select_element DEFINITION PUBLIC INHERITING FROM cl_dd_form_element
  FRIENDS cl_dd_form_area.
  PUBLIC SECTION.

    DATA options TYPE sdydo_option_tab.
    DATA value TYPE sdydo_value.

    EVENTS selected
      EXPORTING
        VALUE(sender) TYPE REF TO cl_dd_select_element.

    METHODS set_value
      IMPORTING
        value TYPE sdydo_value.

  PRIVATE SECTION.
    DATA tooltip TYPE string.
    DATA a11y_label TYPE string.

ENDCLASS.

CLASS cl_dd_select_element IMPLEMENTATION.
  METHOD set_value.
    me->value = value.
    RAISE EVENT selected EXPORTING sender = me.
  ENDMETHOD.
ENDCLASS.
