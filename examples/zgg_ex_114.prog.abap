REPORT zgg_ex_114.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 40.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

* S and I let PAI go on; W and E stop it and show the screen again.
MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR: gv_ok_code, gv_state.
  CASE lv_ok_code.
    WHEN 'SUCCESS'.
      MESSAGE 'Flight saved' TYPE 'S'.
      gv_state = 'PAI went on after S'.
    WHEN 'INFO'.
      MESSAGE 'Seats are limited' TYPE 'I'.
      gv_state = 'PAI went on after I'.
    WHEN 'WARNING'.
      MESSAGE 'The flight is almost full' TYPE 'W'.
      gv_state = 'PAI went on after W'.
    WHEN 'ERROR'.
      MESSAGE 'The flight is fully booked' TYPE 'E'.
      gv_state = 'PAI went on after E'.
    WHEN 'LIKE'.
      MESSAGE 'Saved, but check the seats' TYPE 'S' DISPLAY LIKE 'E'.
      gv_state = 'PAI went on after S like E'.
  ENDCASE.
ENDMODULE.
