REPORT zgg_ex_020.

* A select-option for a field of the dictionary table ZSFLIGHT: one airline,
* without intervals or multiple selection, LH by default.

TABLES zsflight.

SELECT-OPTIONS s_carr FOR zsflight-carrid DEFAULT 'LH' NO-EXTENSION NO INTERVALS.

DATA gt_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'AA' connid = '0017' )
    ( carrid = 'LH' connid = '0400' )
    ( carrid = 'LH' connid = '0402' ) ).
  LOOP AT gt_flights INTO zsflight WHERE carrid IN s_carr.
    WRITE: / zsflight-carrid, zsflight-connid.
  ENDLOOP.
