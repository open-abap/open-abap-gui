REPORT zgg_ex_205.

* USING parameters typed SORTED TABLE OF and HASHED TABLE OF a line type.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gt_sorted TYPE SORTED TABLE OF ty_order WITH UNIQUE KEY id.
DATA gt_hashed TYPE HASHED TABLE OF ty_order WITH UNIQUE KEY id.

START-OF-SELECTION.
  gt_sorted = VALUE #( ( id = 2 qty = 7 ) ( id = 1 qty = 5 ) ).
  gt_hashed = gt_sorted.
  PERFORM show USING gt_sorted gt_hashed.

FORM show USING it_sorted TYPE SORTED TABLE OF ty_order
                it_hashed TYPE HASHED TABLE OF ty_order.
  LOOP AT it_sorted INTO DATA(ls_order).
    WRITE: / ls_order-id, ls_order-qty.
  ENDLOOP.
  WRITE: / 'Hashed', lines( it_hashed ).
ENDFORM.
