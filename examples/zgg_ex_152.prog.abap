REPORT zgg_ex_152.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_finished FOR EVENT finished OF cl_gui_timer.
ENDCLASS.

DATA go_timer TYPE REF TO cl_gui_timer.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_seconds TYPE i.
DATA gv_state TYPE c LENGTH 40.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_finished.
    gv_seconds = gv_seconds + 1.
    go_timer->run( ).
    cl_gui_cfw=>set_new_ok_code( 'TICK' ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  gv_state = 'Timer stopped'.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_timer IS INITIAL.
    CREATE OBJECT go_timer.
    SET HANDLER lcl_handler=>on_finished FOR go_timer.
    go_timer->interval = 1.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'START'.
      go_timer->run( ).
      gv_state = 'Timer running'.
    WHEN 'STOP'.
      go_timer->cancel( ).
      gv_state = 'Timer stopped'.
    WHEN 'RESET'.
      CLEAR gv_seconds.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
