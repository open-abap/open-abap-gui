CLASS cx_salv_msg DEFINITION PUBLIC INHERITING FROM cx_salv_error.
  PUBLIC SECTION.
    INTERFACES if_alv_message.
ENDCLASS.

CLASS cx_salv_msg IMPLEMENTATION.

  METHOD if_alv_message~get_message.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
