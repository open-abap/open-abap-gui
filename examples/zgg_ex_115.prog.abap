REPORT zgg_ex_115.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_connid TYPE n LENGTH 4 VALUE '0400'.
DATA gv_seats TYPE n LENGTH 5 VALUE '00180'.
DATA gv_state TYPE c LENGTH 40.

START-OF-SELECTION.
  CALL SCREEN 100.

* Each screen sets its own status and title; the status decides which
* functions the toolbars offer.
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'LIST'.
  SET TITLEBAR 'LIST'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'DETAIL'.
    CLEAR gv_ok_code.
    LEAVE TO SCREEN 200.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS 'DETAIL'.
  SET TITLEBAR 'DETAIL' WITH gv_connid.
ENDMODULE.

MODULE exit_0200 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 100.
ENDMODULE.

MODULE user_command_0200 INPUT.
  IF gv_ok_code = 'SAVE'.
    gv_state = |Flight { gv_connid } saved with { gv_seats } seats|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
