CLASS zcl_gg_gui_demo_helper DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES ty_log_line TYPE string.
    TYPES ty_log_lines TYPE STANDARD TABLE OF ty_log_line WITH EMPTY KEY.

    CLASS-METHODS add_log
      IMPORTING
        event TYPE string
      CHANGING
        log   TYPE ty_log_lines.

    CLASS-METHODS reset_log
      IMPORTING
        initial_event TYPE string
      CHANGING
        log           TYPE ty_log_lines.
ENDCLASS.

CLASS zcl_gg_gui_demo_helper IMPLEMENTATION.
  METHOD add_log.
    APPEND event TO log.
  ENDMETHOD.

  METHOD reset_log.
    CLEAR log.
    APPEND initial_event TO log.
  ENDMETHOD.
ENDCLASS.
