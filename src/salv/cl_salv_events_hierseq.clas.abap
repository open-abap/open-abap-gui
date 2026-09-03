CLASS cl_salv_events_hierseq DEFINITION PUBLIC INHERITING FROM cl_salv_events.
  PUBLIC SECTION.

    EVENTS link_click
      EXPORTING
        VALUE(level)  TYPE i
        VALUE(row)    TYPE i
        VALUE(column) TYPE lvc_fname.

    EVENTS double_click
      EXPORTING
        VALUE(level)  TYPE i
        VALUE(row)    TYPE i
        VALUE(column) TYPE lvc_fname.

ENDCLASS.

CLASS cl_salv_events_hierseq IMPLEMENTATION.
ENDCLASS.
