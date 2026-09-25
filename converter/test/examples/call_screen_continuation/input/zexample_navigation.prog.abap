REPORT zexample_navigation.

PARAMETERS p_target TYPE c LENGTH 1 DEFAULT 'S'.

DATA gv_step TYPE i.

START-OF-SELECTION.
  gv_step = 1.
  WRITE: / 'Before navigation, step', gv_step.
  CASE p_target.
    WHEN 'S'.
      CALL SCREEN 0100.
    WHEN 'R'.
      SUBMIT zexample_other AND RETURN.
  ENDCASE.
  gv_step = 2.
  WRITE: / 'After navigation, step', gv_step.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'SCREEN'.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
