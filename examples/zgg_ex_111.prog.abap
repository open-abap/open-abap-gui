REPORT zgg_ex_111.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_trail TYPE c LENGTH 60 VALUE '100'.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

* CALL SCREEN starts a screen sequence; LEAVE TO SCREEN 0 ends it and
* continues after the CALL SCREEN that started it.
MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'CALL200'.
    CLEAR gv_ok_code.
    gv_trail = |{ gv_trail } > 200|.
    CALL SCREEN 200 STARTING AT 10 4.
    gv_trail = |{ gv_trail } > back in 100|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.

MODULE status_modal OUTPUT.
  SET PF-STATUS 'MODAL'.
ENDMODULE.

MODULE exit_modal INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0200 INPUT.
  IF gv_ok_code = 'CALL300'.
    CLEAR gv_ok_code.
    gv_trail = |{ gv_trail } > 300|.
    CALL SCREEN 300 STARTING AT 20 8.
    gv_trail = |{ gv_trail } > back in 200|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
