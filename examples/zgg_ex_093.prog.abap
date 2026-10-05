REPORT zgg_ex_093.

* Find and Find next of the list processor search the list the program
* wrote; the program is not called for them.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'AA' connid = '0017' cityfrom = 'New York' cityto = 'San Francisco' )
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' )
    ( carrid = 'SQ' connid = '0026' cityfrom = 'Singapore' cityto = 'Frankfurt' )
    ( carrid = 'LH' connid = '0402' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'JL' connid = '0407' cityfrom = 'Tokyo' cityto = 'Frankfurt' ) ).

  WRITE: / 'Airline', 10 'Flight', 18 'From', 40 'To'.
  ULINE.
  LOOP AT gt_flights INTO gs_flight.
    WRITE: / gs_flight-carrid, 10 gs_flight-connid, 18 gs_flight-cityfrom, 40 gs_flight-cityto.
  ENDLOOP.
