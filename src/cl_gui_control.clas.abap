CLASS cl_gui_control DEFINITION PUBLIC INHERITING FROM cl_gui_object.
  PUBLIC SECTION.

    CLASS-DATA www_active TYPE abap_bool READ-ONLY.

    CLASS-METHODS set_focus
      IMPORTING
        control TYPE REF TO cl_gui_control.

    METHODS set_enable
      IMPORTING
        enable TYPE c.

    METHODS set_visible
      IMPORTING
        visible TYPE c.

    METHODS set_registered_events
      IMPORTING
        events TYPE any.

    CLASS-METHODS get_focus
      EXPORTING
        control TYPE REF TO cl_gui_control.

    METHODS free.

    METHODS set_alignment
      IMPORTING
        alignment TYPE i.

    METHODS get_height
      EXPORTING
        height TYPE i
      EXCEPTIONS
        cntl_error.

ENDCLASS.

CLASS cl_gui_control IMPLEMENTATION.
  METHOD get_height.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_alignment.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_focus.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD free.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_registered_events.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_visible.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_focus.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_enable.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.