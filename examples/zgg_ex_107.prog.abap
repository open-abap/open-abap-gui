REPORT zgg_ex_107.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_top_line TYPE i.

CONTROLS tc_flights TYPE TABLEVIEW USING SCREEN 100.

START-OF-SELECTION.
  DO 12 TIMES.
    APPEND VALUE #( carrid = 'LH' connid = |{ 400 + sy-index WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
                    cityfrom = 'Frankfurt' cityto = |City { sy-index }| ) TO gt_flights.
  ENDDO.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  tc_flights-lines = lines( gt_flights ).
  gv_top_line = tc_flights-top_line.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

* The page functions move the first line shown by the visible lines.
MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'P--'.
      tc_flights-top_line = 1.
    WHEN 'P-'.
      tc_flights-top_line = nmax( val1 = 1
                                  val2 = tc_flights-top_line - sy-loopc ).
    WHEN 'P+'.
      tc_flights-top_line = nmin( val1 = tc_flights-lines - sy-loopc + 1
                                  val2 = tc_flights-top_line + sy-loopc ).
    WHEN 'P++'.
      tc_flights-top_line = tc_flights-lines - sy-loopc + 1.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
