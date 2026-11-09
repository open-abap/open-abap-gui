REPORT zgg_ex_194.

* A TABLES parameter typed STRUCTURE with a dictionary structure.

DATA gt_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.

START-OF-SELECTION.
  gt_flights = VALUE #( ( carrid = 'LH' connid = '0400' ) ( carrid = 'AA' connid = '0017' ) ).
  PERFORM show TABLES gt_flights.

FORM show TABLES pt_flights STRUCTURE zsflight.
  LOOP AT pt_flights INTO DATA(ls_flight).
    WRITE: / ls_flight-carrid, ls_flight-connid.
  ENDLOOP.
ENDFORM.
