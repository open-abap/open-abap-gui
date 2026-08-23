CLASS cl_salv_events_hierseq DEFINITION PUBLIC.
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

    EVENTS added_function
      EXPORTING
        VALUE(e_salv_function) TYPE salv_de_function.

ENDCLASS.

CLASS cl_salv_events_hierseq IMPLEMENTATION.
ENDCLASS.
