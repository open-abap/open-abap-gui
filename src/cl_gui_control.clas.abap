CLASS cl_gui_control DEFINITION PUBLIC INHERITING FROM cl_gui_object.
  PUBLIC SECTION.
    DATA parent TYPE REF TO cl_gui_container READ-ONLY.

    CONSTANTS align_at_bottom TYPE i VALUE 8.
    CONSTANTS align_at_left TYPE i VALUE 1.
    CONSTANTS align_at_right TYPE i VALUE 2.
    CONSTANTS align_at_top TYPE i VALUE 4.

    CONSTANTS ws_clipsiblings TYPE i VALUE 67108864.

    CONSTANTS lifetime_default TYPE i VALUE 0.
    CONSTANTS lifetime_dynpro TYPE i VALUE 1.
    CONSTANTS lifetime_imode TYPE i VALUE 2.

    CONSTANTS mode_run TYPE i VALUE 0.
    CONSTANTS mode_design TYPE i VALUE 1.

    CONSTANTS metric_default TYPE i VALUE 0.
    CONSTANTS metric_pixel TYPE i VALUE 1.
    CONSTANTS metric_mm TYPE i VALUE 2.

    CONSTANTS state_alive TYPE i VALUE 0.
    CONSTANTS state_alive_on_other_screen TYPE i VALUE 1.
    CONSTANTS state_dead TYPE i VALUE -1.

    CLASS-METHODS set_focus
      IMPORTING
        control TYPE REF TO cl_gui_control.

    METHODS get_width
      EXPORTING
        width TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS set_width
      IMPORTING
        width TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS set_height
      IMPORTING
        height TYPE i
      EXCEPTIONS
        cntl_error.

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

    METHODS set_position
      IMPORTING
        height TYPE i OPTIONAL
        left   TYPE i OPTIONAL
        top    TYPE i OPTIONAL
        width  TYPE i OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error.

ENDCLASS.

CLASS cl_gui_control IMPLEMENTATION.
  METHOD set_position.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_width.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_width.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_height.
    RETURN. " todo, implement method
  ENDMETHOD.

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