REPORT zgg_ex_110.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_name TYPE c LENGTH 30 VALUE 'Ada Lovelace'.
DATA gv_new_name TYPE c LENGTH 30.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'CHANGE'.
    CLEAR gv_ok_code.
    gv_new_name = gv_name.
    CALL SCREEN 200 STARTING AT 10 5 ENDING AT 60 8.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.

* A modal dialog box: its own status and title, and it returns to the
* screen that called it.
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'DIALOG'.
  SET TITLEBAR 'DIALOG'.
ENDMODULE.

MODULE cancel_0200 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0200 INPUT.
  IF gv_ok_code = 'OK'.
    gv_name = gv_new_name.
    CLEAR gv_ok_code.
    LEAVE TO SCREEN 0.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
