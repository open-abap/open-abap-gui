CLASS zcl_example_counter DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS increment RETURNING VALUE(ro_self) TYPE REF TO zcl_example_counter.
    METHODS add IMPORTING iv_amount TYPE i.
    METHODS get_value RETURNING VALUE(rv_value) TYPE i.
  PRIVATE SECTION.
    DATA mv_value TYPE i.
ENDCLASS.

CLASS zcl_example_counter IMPLEMENTATION.
  METHOD increment.
    mv_value = mv_value + 1.
    ro_self = me.
  ENDMETHOD.

  METHOD add.
    mv_value = mv_value + iv_amount.
  ENDMETHOD.

  METHOD get_value.
    rv_value = mv_value.
  ENDMETHOD.
ENDCLASS.
