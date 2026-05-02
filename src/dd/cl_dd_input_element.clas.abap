CLASS cl_dd_input_element DEFINITION PUBLIC.
  PUBLIC SECTION.

    DATA value TYPE sdydo_value.

    METHODS set_value
      IMPORTING
        value TYPE sdydo_value OPTIONAL.
ENDCLASS.

CLASS cl_dd_input_element IMPLEMENTATION.
  METHOD set_value.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.