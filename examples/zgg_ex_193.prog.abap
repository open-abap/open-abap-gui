REPORT zgg_ex_193.

* FORMs in an include, typed with types from the TOP include.

INCLUDE zgg_ex_193_top.
INCLUDE zgg_ex_193_f01.

START-OF-SELECTION.
  DATA lt_orders TYPE ty_orders.
  DATA lv_total TYPE i.
  PERFORM fill TABLES lt_orders.
  PERFORM sum USING lt_orders CHANGING lv_total.
  LOOP AT lt_orders INTO DATA(ls_order).
    PERFORM show USING ls_order.
  ENDLOOP.
  WRITE: / 'Total:', lv_total.
