CLASS cl_gui_timer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    DATA interval TYPE i.

    METHODS constructor.

    METHODS run.

    METHODS cancel.

    METHODS reset.

    "! Advances the session clock once. A timer never creates a background
    "! browser task; callers explicitly drive the deterministic clock.
    METHODS tick.

    METHODS get_tick_count
      RETURNING
        VALUE(tick_count) TYPE i.

    EVENTS finished.

  PRIVATE SECTION.
    METHODS is_running
      RETURNING
        VALUE(running) TYPE abap_bool.

    DATA mv_running TYPE abap_bool.
    DATA mv_tick_count TYPE i.
ENDCLASS.

CLASS cl_gui_timer IMPLEMENTATION.

  METHOD constructor.
    interval = 1000.
    mv_running = abap_false.
    CLEAR mv_tick_count.
  ENDMETHOD.

  METHOD run.
    IF interval <= 0.
      interval = 1000.
    ENDIF.
    mv_running = abap_true.
    cl_gui_control=>set_payload( control = me
                                 payload = |running; interval={ interval }; ticks={ mv_tick_count }| ).
  ENDMETHOD.

  METHOD cancel.
    mv_running = abap_false.
    cl_gui_control=>set_payload( control = me
                                 payload = |stopped; interval={ interval }; ticks={ mv_tick_count }| ).
  ENDMETHOD.

  METHOD reset.
    mv_running = abap_false.
    CLEAR mv_tick_count.
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
