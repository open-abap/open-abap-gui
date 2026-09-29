PROGRAM zexample_okcode.

DATA ok_code TYPE sy-ucomm.
DATA gv_detail_ok TYPE sy-ucomm.
DATA gv_save_ok TYPE sy-ucomm.
DATA gv_last TYPE c LENGTH 20.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE user_command_0100 INPUT.
  gv_save_ok = ok_code.
  CLEAR ok_code.
  CASE gv_save_ok.
    WHEN 'BACK'.
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      LEAVE TO SCREEN 0200.
    WHEN 'CANC'.
      gv_last = 'CANCELED'.
  ENDCASE.
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE user_command_0200 INPUT.
  gv_save_ok = gv_detail_ok.
  CLEAR gv_detail_ok.
  CASE gv_save_ok.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0100.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CANC'.
      gv_last = 'DETAIL CANCELED'.
  ENDCASE.
ENDMODULE.
