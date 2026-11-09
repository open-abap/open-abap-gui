REPORT zgg_ex_203.

* A USING parameter typed STRUCTURE with a structure.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gs_order TYPE ty_order.

START-OF-SELECTION.
  gs_order = VALUE #( id = 1 qty = 5 ).
  PERFORM show USING gs_order.

FORM show USING is_order STRUCTURE gs_order.
  WRITE: / is_order-id, is_order-qty.
ENDFORM.
