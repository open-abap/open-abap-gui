REPORT zgg_ex_195.

* A TABLES parameter typed STRUCTURE with a table with header line.

DATA: BEGIN OF gt_orders OCCURS 0,
        id  TYPE i,
        qty TYPE i,
      END OF gt_orders.

START-OF-SELECTION.
  gt_orders-id = 1.
  gt_orders-qty = 5.
  APPEND gt_orders.
  gt_orders-id = 2.
  gt_orders-qty = 7.
  APPEND gt_orders.
  PERFORM show TABLES gt_orders.

FORM show TABLES pt_orders STRUCTURE gt_orders.
  LOOP AT pt_orders.
    WRITE: / pt_orders-id, pt_orders-qty.
  ENDLOOP.
ENDFORM.
