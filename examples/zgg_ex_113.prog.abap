REPORT zgg_ex_113.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_customer TYPE c LENGTH 20.
DATA gv_state TYPE c LENGTH 40.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

* Exit and Cancel are of type E: this module runs before the required field
* is checked, so they leave even with the field empty.
MODULE exit_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CANCEL'.
      CLEAR gv_ok_code.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

* Back is an ordinary function: it reaches PAI only with the required field
* filled.
MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'BACK'.
      CLEAR gv_ok_code.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      gv_state = |Booked for { gv_customer }|.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
