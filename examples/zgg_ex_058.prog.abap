PROGRAM zgg_ex_058.

* A module pool: its transaction starts screen 100. Details goes to screen
* 200 with SET SCREEN and LEAVE SCREEN, Back returns, and Back on screen 100
* ends the transaction with LEAVE TO SCREEN 0.

DATA gv_ok_code TYPE sy-ucomm.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'FLOW'.
  SET TITLEBAR 'FLOW'.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'NEXT'.
      CLEAR gv_ok_code.
      SET SCREEN 200.
      LEAVE SCREEN.
    WHEN 'BACK'.
      CLEAR gv_ok_code.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

MODULE user_command_0200 INPUT.
  IF gv_ok_code = 'BACK'.
    CLEAR gv_ok_code.
    SET SCREEN 100.
    LEAVE SCREEN.
  ENDIF.
ENDMODULE.
