CLASS zcl_example_document DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    EVENTS status_changed EXPORTING VALUE(ev_status) TYPE string.
    METHODS set_status IMPORTING iv_status TYPE string.
ENDCLASS.

CLASS zcl_example_document IMPLEMENTATION.
  METHOD set_status.
    RAISE EVENT status_changed EXPORTING ev_status = iv_status.
  ENDMETHOD.
ENDCLASS.
