PROGRAM zexample_dialog.

DATA gv_name TYPE c LENGTH 20.
DATA gv_greeting TYPE c LENGTH 40.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  SET TITLEBAR 'MAIN'.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'GREET'.
      gv_greeting = |Hello { gv_name }|.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
