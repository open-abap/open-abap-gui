REPORT zgg_ex_112.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_after TYPE c LENGTH 50.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

* SET SCREEN only changes the next screen; PAI goes on. LEAVE TO SCREEN
* ends PAI at once and goes there.
MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'SET'.
      CLEAR gv_ok_code.
      SET SCREEN 200.
      gv_after = 'went on after SET SCREEN'.
    WHEN 'LEAVE'.
      CLEAR gv_ok_code.
      gv_after = 'ended at LEAVE TO SCREEN'.
      LEAVE TO SCREEN 200.
  ENDCASE.
ENDMODULE.

MODULE back_0200 INPUT.
  CLEAR gv_ok_code.
  SET SCREEN 100.
  LEAVE SCREEN.
ENDMODULE.
