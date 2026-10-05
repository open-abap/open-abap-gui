REPORT zgg_ex_109.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_dynnr TYPE sy-dynnr VALUE '0110'.
DATA gv_active TYPE c LENGTH 20.
DATA gv_from TYPE c LENGTH 20 VALUE 'Frankfurt'.
DATA gv_to TYPE c LENGTH 20 VALUE 'New York'.
DATA gv_plane TYPE c LENGTH 10 VALUE 'A340-600'.

CONTROLS ts_flight TYPE TABSTRIP.

START-OF-SELECTION.
  ts_flight-activetab = 'TAB_ROUTE'.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  gv_active = ts_flight-activetab.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

* A tab is a pushbutton: PAI sets the active tab and the screen it shows.
MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'TAB_ROUTE'.
      ts_flight-activetab = 'TAB_ROUTE'.
      gv_dynnr = '0110'.
    WHEN 'TAB_PLANE'.
      ts_flight-activetab = 'TAB_PLANE'.
      gv_dynnr = '0120'.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
