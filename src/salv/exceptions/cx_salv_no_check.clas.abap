CLASS cx_salv_no_check DEFINITION PUBLIC INHERITING FROM cx_no_check.
  PUBLIC SECTION.
    INTERFACES if_alv_message.
ENDCLASS.

CLASS cx_salv_no_check IMPLEMENTATION.

  METHOD if_alv_message~get_message.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
