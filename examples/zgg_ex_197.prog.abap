REPORT zgg_ex_197.

* A CHANGING parameter typed LIKE a structure.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gs_order TYPE ty_order.

START-OF-SELECTION.
  PERFORM fill CHANGING gs_order.
  WRITE: / gs_order-id, gs_order-qty.

FORM fill CHANGING cs_order LIKE gs_order.
  cs_order = VALUE #( id = 1 qty = 5 ).
ENDFORM.
