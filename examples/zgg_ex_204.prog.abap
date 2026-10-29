REPORT zgg_ex_204.

* A USING parameter typed TYPE LINE OF a table type.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gt_orders TYPE ty_orders.

START-OF-SELECTION.
  gt_orders = VALUE #( ( id = 1 qty = 5 ) ( id = 2 qty = 7 ) ).
  LOOP AT gt_orders INTO DATA(ls_order).
    PERFORM show USING ls_order.
  ENDLOOP.

FORM show USING is_order TYPE LINE OF ty_orders.
  WRITE: / is_order-id, is_order-qty.
ENDFORM.
