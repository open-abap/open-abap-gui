REPORT zgg_ex_101.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_name TYPE c LENGTH 20 VALUE 'Ada'.
DATA gv_city TYPE c LENGTH 20.
DATA gv_state TYPE c LENGTH 40.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  IF gv_city IS INITIAL.
    SET CURSOR FIELD 'GV_CITY'.
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

* An error in a FIELD module keeps only that field ready for input and puts
* the cursor on it.
MODULE check_city INPUT.
  IF gv_city IS INITIAL.
    MESSAGE 'Enter a city' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'VALIDATE'.
    gv_state = |{ gv_name } lives in { gv_city }|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
