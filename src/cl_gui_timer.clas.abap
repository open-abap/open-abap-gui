CLASS cl_gui_timer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    DATA interval TYPE i.

    METHODS run.

    METHODS cancel.

    EVENTS finished.
ENDCLASS.

CLASS cl_gui_timer IMPLEMENTATION.

  METHOD run.
    RETURN.
  ENDMETHOD.

  METHOD cancel.
    RETURN.
  ENDMETHOD.

ENDCLASS.
