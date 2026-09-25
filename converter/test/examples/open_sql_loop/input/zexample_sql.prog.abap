REPORT zexample_sql.

TYPES: BEGIN OF ty_flight,
         carrid TYPE s_carr_id,
         connid TYPE s_conn_id,
         price  TYPE s_price,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH EMPTY KEY.
DATA gs_flight TYPE ty_flight.
DATA gv_price TYPE s_price.

PARAMETERS p_carr TYPE s_carr_id DEFAULT 'LH'.

START-OF-SELECTION.
  SELECT carrid connid price FROM sflight INTO TABLE gt_flights WHERE carrid = p_carr.
  LOOP AT gt_flights INTO gs_flight.
    WRITE: / gs_flight-carrid, gs_flight-connid, gs_flight-price.
  ENDLOOP.

  SELECT carrid connid price FROM sflight INTO gs_flight UP TO 3 ROWS.
    WRITE: / gs_flight-connid.
  ENDSELECT.

  SELECT SINGLE price FROM sflight INTO gv_price WHERE carrid = p_carr.
  WRITE: / 'First price', gv_price.
