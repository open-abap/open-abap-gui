REPORT zgg_ex_108.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_dynnr TYPE sy-dynnr VALUE '0110'.
DATA gv_name TYPE c LENGTH 30 VALUE 'Ada Lovelace'.
DATA gv_street TYPE c LENGTH 30 VALUE 'St James Square 12'.
DATA gv_city TYPE c LENGTH 20 VALUE 'London'.
DATA gv_phone TYPE c LENGTH 20.
DATA gv_summary TYPE c LENGTH 60.

START-OF-SELECTION.
  CALL SCREEN 100.

* The subscreen area shows one of two screens; their fields keep their
* values while the other one is shown.
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  gv_summary = |{ gv_name }, { gv_city }, { gv_phone }|.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'ADDRESS'.
      gv_dynnr = '0110'.
    WHEN 'CONTACT'.
      gv_dynnr = '0120'.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
