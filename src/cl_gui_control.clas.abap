CLASS cl_gui_control DEFINITION PUBLIC.
  PUBLIC SECTION.

    CLASS-DATA www_active TYPE abap_bool READ-ONLY.

    CLASS-METHODS set_focus
      IMPORTING
        control TYPE REF TO cl_gui_control.
ENDCLASS.

CLASS cl_gui_control IMPLEMENTATION.

  METHOD set_focus.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.