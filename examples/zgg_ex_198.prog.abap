REPORT zgg_ex_198.

* A USING parameter typed LIKE an internal table.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gt_orders TYPE ty_orders.

START-OF-SELECTION.
  gt_orders = VALUE #( ( id = 1 qty = 5 ) ( id = 2 qty = 7 ) ).
  PERFORM show USING gt_orders.

FORM show USING it_orders LIKE gt_orders.
  LOOP AT it_orders INTO DATA(ls_order).
    WRITE: / ls_order-id, ls_order-qty.
  ENDLOOP.
ENDFORM.
