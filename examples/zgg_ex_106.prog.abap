REPORT zgg_ex_106.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 50.

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

* Runs for each line of the table control whose cities were changed.
MODULE check_flight INPUT.
  IF gs_flight-cityfrom = gs_flight-cityto.
    MESSAGE |Flight { gs_flight-carrid } { gs_flight-connid } cannot end where it starts| TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE modify_flight INPUT.
  MODIFY gt_flights FROM gs_flight INDEX tc_flights-current_line.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SAVE'.
    READ TABLE gt_flights INTO gs_flight INDEX 2.
    gv_state = |Saved; LH 0400 flies { gs_flight-cityfrom } - { gs_flight-cityto }|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
