CLASS cl_gui_timer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    DATA interval TYPE i.

    METHODS run.

    METHODS cancel.

    "! Advances the session clock once. A timer never creates a background
    "! browser task; callers explicitly drive the deterministic clock.
    METHODS tick.

    METHODS get_tick_count
      RETURNING
        VALUE(tick_count) TYPE i.

    METHODS is_running
      RETURNING
        VALUE(running) TYPE abap_bool.

    EVENTS finished.

  PRIVATE SECTION.
    DATA mv_running TYPE abap_bool.
    DATA mv_tick_count TYPE i.
ENDCLASS.

CLASS cl_gui_timer IMPLEMENTATION.

  METHOD run.
    mv_running = abap_true.
    cl_gui_control=>set_payload( control = me
                                 payload = |running; interval={ interval }; ticks={ mv_tick_count }| ).
  ENDMETHOD.

  METHOD cancel.
    mv_running = abap_false.
    cl_gui_control=>set_payload( control = me
                                 payload = |stopped; interval={ interval }; ticks={ mv_tick_count }| ).
  ENDMETHOD.

  METHOD tick.
    IF mv_running = abap_false.
      RETURN.
    ENDIF.
    mv_tick_count = mv_tick_count + 1.
    cl_gui_control=>set_payload( control = me
                                 payload = |running; interval={ interval }; ticks={ mv_tick_count }| ).
    RAISE EVENT finished.
  ENDMETHOD.

  METHOD get_tick_count.
    tick_count = mv_tick_count.
  ENDMETHOD.

  METHOD is_running.
    running = mv_running.
  ENDMETHOD.

ENDCLASS.
