REPORT zgg_ex_092 LINE-SIZE 60 LINE-COUNT 20(1).

* A list longer than the window. The list processor pages through it with
* First page, Previous page, Next page and Last page; the program writes the
* list once and is not called again.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.
DATA gt_cities TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

END-OF-PAGE.
  WRITE / |Page { sy-pagno }|.

TOP-OF-PAGE.
  WRITE: / 'Airline', 10 'Flight', 18 'From', 40 'To'.
  ULINE.

START-OF-SELECTION.
  gt_cities = VALUE #( ( `Frankfurt` ) ( `New York` ) ( `Singapore` )
                       ( `Tokyo` ) ( `Rome` ) ( `San Francisco` ) ).
  DO 80 TIMES.
    gs_flight-carrid = COND #( WHEN sy-index MOD 2 = 0 THEN 'LH' ELSE 'UA' ).
    gs_flight-connid = 400 + sy-index.
    gs_flight-cityfrom = gt_cities[ sy-index MOD 6 + 1 ].
    gs_flight-cityto = gt_cities[ ( sy-index + 2 ) MOD 6 + 1 ].
    APPEND gs_flight TO gt_flights.
  ENDDO.

  LOOP AT gt_flights INTO gs_flight.
    WRITE: / gs_flight-carrid, 10 gs_flight-connid, 18 gs_flight-cityfrom, 40 gs_flight-cityto.
  ENDLOOP.
