REPORT zgg_ex_060.

* Two functions of the program's own, shown by their text and on F5 and F6;
* each writes the flights in another order.

TYPES: BEGIN OF ty_flight,
         carrid TYPE c LENGTH 3,
         connid TYPE n LENGTH 4,
         seats  TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.

START-OF-SELECTION.
  SET PF-STATUS 'FLIGHTS'.
  gt_flights = VALUE #(
    ( carrid = 'UA' connid = '0941' seats = 12 )
    ( carrid = 'LH' connid = '0400' seats = 40 )
    ( carrid = 'AA' connid = '0017' seats = 3 ) ).
  PERFORM show.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'BY_CARRIER'.
      SORT gt_flights BY carrid.
    WHEN 'BY_SEATS'.
      SORT gt_flights BY seats DESCENDING.
  ENDCASE.
  PERFORM show.

FORM show.
  LOOP AT gt_flights INTO gs_flight.
    WRITE: / gs_flight-carrid, gs_flight-connid, gs_flight-seats.
  ENDLOOP.
ENDFORM.
