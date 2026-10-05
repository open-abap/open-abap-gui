REPORT zgg_ex_100.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_input TYPE c LENGTH 30 VALUE 'initial'.
DATA gv_upper TYPE c LENGTH 30.
DATA gv_output TYPE c LENGTH 40.

START-OF-SELECTION.
  CALL SCREEN 100.

* PBO fills the screen fields from the program, PAI brings them back.
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  gv_upper = to_upper( gv_input ).
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'APPLY'.
    gv_output = |accepted: { gv_input }|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
