REPORT zgg_ex_206.

* USING parameters typed with the generic table types.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gt_orders TYPE ty_orders.

START-OF-SELECTION.
  gt_orders = VALUE #( ( id = 1 qty = 5 ) ( id = 2 qty = 7 ) ).
  PERFORM show USING gt_orders gt_orders gt_orders.

FORM show USING it_standard TYPE STANDARD TABLE
                it_index TYPE INDEX TABLE
                it_any TYPE ANY TABLE.
  WRITE: / 'Lines', lines( it_standard ), lines( it_index ), lines( it_any ).
ENDFORM.
