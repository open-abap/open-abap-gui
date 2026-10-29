REPORT zgg_ex_200.

* A USING parameter typed LIKE a component of a structure.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gs_order TYPE ty_order.

START-OF-SELECTION.
  gs_order = VALUE #( id = 1 qty = 5 ).
  PERFORM show USING gs_order-qty.

FORM show USING iv_qty LIKE gs_order-qty.
  WRITE: / 'Quantity', iv_qty.
ENDFORM.
