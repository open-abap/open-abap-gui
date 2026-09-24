CLASS zcl_example_order DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    EVENTS status_changed EXPORTING VALUE(ev_status) TYPE string.
    CLASS-EVENTS order_created.
    CLASS-METHODS create RETURNING VALUE(ro_order) TYPE REF TO zcl_example_order.
    METHODS set_status IMPORTING iv_status TYPE string.
ENDCLASS.

CLASS zcl_example_order IMPLEMENTATION.
  METHOD create.
    ro_order = NEW #( ).
    RAISE EVENT order_created.
  ENDMETHOD.

  METHOD set_status.
    RAISE EVENT status_changed EXPORTING ev_status = iv_status.
  ENDMETHOD.
ENDCLASS.
