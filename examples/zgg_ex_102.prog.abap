REPORT zgg_ex_102.

TYPES: BEGIN OF ty_carrier,
         carrid   TYPE c LENGTH 3,
         carrname TYPE c LENGTH 20,
       END OF ty_carrier.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_carrid TYPE c LENGTH 3.
DATA gt_carriers TYPE STANDARD TABLE OF ty_carrier WITH DEFAULT KEY.

START-OF-SELECTION.
  gt_carriers = VALUE #(
    ( carrid = 'AA' carrname = 'American Airlines' )
    ( carrid = 'LH' carrname = 'Lufthansa' )
    ( carrid = 'UA' carrname = 'United Airlines' ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

* F4 on the field: the program's own value help.
MODULE f4_carrid INPUT.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'CARRID'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'GV_CARRID'
      value_org   = 'S'
    TABLES
      value_tab   = gt_carriers.
ENDMODULE.

* F1 on the field: the program's own help text.
MODULE f1_carrid INPUT.
  CALL FUNCTION 'POPUP_TO_INFORM'
    EXPORTING
      titel = 'Airline'
      txt1  = 'The two-letter code of the airline,'
      txt2  = 'for example LH for Lufthansa.'.
ENDMODULE.
