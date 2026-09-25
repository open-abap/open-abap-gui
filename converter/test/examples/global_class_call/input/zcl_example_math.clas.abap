CLASS zcl_example_math DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS sum_to
      IMPORTING iv_count        TYPE i
      RETURNING VALUE(rv_total) TYPE i.
ENDCLASS.

CLASS zcl_example_math IMPLEMENTATION.
  METHOD sum_to.
    DO iv_count TIMES.
      rv_total = rv_total + sy-index.
    ENDDO.
  ENDMETHOD.
ENDCLASS.
