REPORT zgg_ex_098.

TYPES: BEGIN OF ty_flight,
         carrid TYPE c LENGTH 3,
         connid TYPE n LENGTH 4,
         seats  TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gv_view TYPE string VALUE 'FLIGHTS'.

START-OF-SELECTION.
  PERFORM load.
  PERFORM show.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'FILTER'.
      DELETE gt_flights WHERE carrid <> 'LH'.
      gv_view = 'FILTERED'.
    WHEN 'SORT'.
      SORT gt_flights BY seats DESCENDING.
      gv_view = 'SORTED'.
    WHEN 'REFRESH'.
      PERFORM load.
      gv_view = 'FLIGHTS'.
  ENDCASE.
  PERFORM show.

FORM load.
  gt_flights = VALUE #( ( carrid = 'LH' connid = '0400' seats = 180 )
                        ( carrid = 'AA' connid = '0017' seats = 210 )
                        ( carrid = 'LH' connid = '0402' seats = 240 )
                        ( carrid = 'UA' connid = '0941' seats = 150 ) ).
ENDFORM.

FORM show.
  SET PF-STATUS 'LIST'.
  SET TITLEBAR 'VIEW' WITH gv_view.
  LOOP AT gt_flights INTO DATA(ls_flight).
    WRITE: / ls_flight-carrid, ls_flight-connid, ls_flight-seats.
  ENDLOOP.
ENDFORM.
