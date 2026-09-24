CLASS zcl_example_shared DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS describe
      IMPORTING iv_who  TYPE string
      EXPORTING ev_text TYPE string.
ENDCLASS.

CLASS zcl_example_shared IMPLEMENTATION.
  METHOD describe.
    ev_text = |Called from { iv_who }|.
  ENDMETHOD.
ENDCLASS.
