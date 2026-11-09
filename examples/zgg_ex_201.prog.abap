REPORT zgg_ex_201.

* A USING parameter typed LIKE a data reference variable.

TYPES: BEGIN OF ty_order,
         id  TYPE i,
         qty TYPE i,
       END OF ty_order.
TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH DEFAULT KEY.

DATA gs_order TYPE ty_order.
DATA gr_order TYPE REF TO ty_order.

START-OF-SELECTION.
  gs_order = VALUE #( id = 1 qty = 5 ).
  gr_order = REF #( gs_order ).
  PERFORM show USING gr_order.

FORM show USING ir_order LIKE gr_order.
  WRITE: / ir_order->id, ir_order->qty.
ENDFORM.
