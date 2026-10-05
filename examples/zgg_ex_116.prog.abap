REPORT zgg_ex_116.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

TYPES: BEGIN OF ty_carrier,
         carrid   TYPE c LENGTH 3,
         carrname TYPE c LENGTH 20,
       END OF ty_carrier.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_carrid TYPE c LENGTH 3 VALUE 'LH'.
DATA gt_carriers TYPE STANDARD TABLE OF ty_carrier WITH DEFAULT KEY.
DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_shown TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.

CONTROLS tc_flights TYPE TABLEVIEW USING SCREEN 200.

START-OF-SELECTION.
  gt_carriers = VALUE #(
    ( carrid = 'LH' carrname = 'Lufthansa' )
    ( carrid = 'UA' carrname = 'United Airlines' ) ).
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'LH' connid = '0402' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' ) ).
  CALL SCREEN 100.

* Screen 100 chooses the airline, screen 200 edits its flights.
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'HEADER'.
  SET TITLEBAR 'HEADER'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE check_carrid INPUT.
  IF NOT line_exists( gt_carriers[ carrid = gv_carrid ] ).
    MESSAGE |Airline { gv_carrid } does not exist| TYPE 'E'.
  ENDIF.
ENDMODULE.

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

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'EDIT'.
    CLEAR gv_ok_code.
    gt_shown = VALUE #( FOR ls_flight IN gt_flights WHERE ( carrid = gv_carrid ) ( ls_flight ) ).
    LEAVE TO SCREEN 200.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS 'ITEMS'.
  SET TITLEBAR 'ITEMS' WITH gv_carrid.
  tc_flights-lines = lines( gt_shown ).
ENDMODULE.

MODULE exit_0200 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 100.
ENDMODULE.

MODULE modify_flight INPUT.
  MODIFY gt_shown FROM gs_flight INDEX tc_flights-current_line.
ENDMODULE.

MODULE user_command_0200 INPUT.
  IF gv_ok_code = 'SAVE'.
    LOOP AT gt_shown INTO gs_flight.
      MODIFY gt_flights FROM gs_flight TRANSPORTING cityfrom cityto
        WHERE carrid = gs_flight-carrid AND connid = gs_flight-connid.
    ENDLOOP.
    MESSAGE |{ lines( gt_shown ) } flights of { gv_carrid } saved| TYPE 'S'.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
