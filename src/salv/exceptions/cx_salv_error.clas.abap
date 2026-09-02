CLASS cx_salv_error DEFINITION PUBLIC INHERITING FROM cx_static_check.
  PUBLIC SECTION.
    INTERFACES if_alv_message.
ENDCLASS.

CLASS cx_salv_error IMPLEMENTATION.

  METHOD if_alv_message~get_message.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
