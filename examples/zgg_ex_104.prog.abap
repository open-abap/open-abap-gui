REPORT zgg_ex_104.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_from TYPE c LENGTH 20 VALUE 'Frankfurt'.
DATA gv_to TYPE c LENGTH 20 VALUE 'New York'.
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

* An error in a chain keeps every field of the chain ready for input.
MODULE check_route INPUT.
  IF gv_from = gv_to.
    MESSAGE 'From and to must differ' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'CHECK'.
    gv_state = |{ gv_from } to { gv_to }|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
