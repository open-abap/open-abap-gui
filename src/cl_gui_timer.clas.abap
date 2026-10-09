CLASS cl_gui_timer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
* Seconds until FINISHED.
    DATA interval TYPE i.

    METHODS constructor
      IMPORTING
        lifetime   TYPE i OPTIONAL
        parent     TYPE REF TO cl_gui_container OPTIONAL
        shellstyle TYPE i OPTIONAL
      EXCEPTIONS
        error.

    METHODS run
      EXCEPTIONS
        error.

    METHODS cancel
      EXCEPTIONS
        error.

    EVENTS finished.

  PROTECTED SECTION.
* The browser counts the interval down and posts FINISHED, a system event:
* PAI runs only when a handler sets a new OK code.
    METHODS dispatch_frontend_event REDEFINITION.
    METHODS is_application_event REDEFINITION.

  PRIVATE SECTION.
    METHODS is_running
      RETURNING
        VALUE(running) TYPE abap_bool.

    METHODS publish.

    DATA mv_running TYPE abap_bool.
ENDCLASS.

CLASS cl_gui_timer IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    zcl_gg_gui_runtime=>initialize( control = me
                                parent  = parent
                                kind    = 'TIMER' ).
    publish( ).
  ENDMETHOD.

  METHOD run.
    IF interval <= 0.
      RAISE error.
    ENDIF.
    mv_running = abap_true.
    publish( ).
  ENDMETHOD.

  METHOD cancel.
    mv_running = abap_false.
    publish( ).
  ENDMETHOD.

  METHOD publish.
* The payload is what the browser needs to run the timer.
    cl_gui_control=>set_payload(
      control = me
      payload = COND string( WHEN mv_running = abap_true
                             THEN |{ interval }\|{ frontend_event_value( 'FINISHED' ) }|
                             ELSE `` ) ).
  ENDMETHOD.

  METHOD dispatch_frontend_event.
* A timer runs once; the program starts it again for the next interval.
    IF event = 'FINISHED' AND mv_running = abap_true.
      mv_running = abap_false.
      publish( ).
      RAISE EVENT finished.
    ENDIF.
  ENDMETHOD.

  METHOD is_application_event.
    result = abap_false.
  ENDMETHOD.

  METHOD is_running.
    running = mv_running.
  ENDMETHOD.

ENDCLASS.
