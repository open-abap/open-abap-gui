REPORT zgg_ex_105.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.
DATA gv_ok_code TYPE sy-ucomm.

CONTROLS tc_flights TYPE TABLEVIEW USING SCREEN 100.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'AA' connid = '0017' cityfrom = 'New York' cityto = 'San Francisco' )
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  tc_flights-lines = lines( gt_flights ).
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.
