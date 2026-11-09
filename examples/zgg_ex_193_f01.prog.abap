* FORMs of ZGG_EX_193.

FORM fill TABLES ct_orders STRUCTURE gs_order.
  APPEND VALUE #( id = 1 qty = 5 ) TO ct_orders.
  APPEND VALUE #( id = 2 qty = 7 ) TO ct_orders.
ENDFORM.

FORM sum USING it_orders TYPE ty_orders
         CHANGING cv_total TYPE i.
  LOOP AT it_orders INTO DATA(ls_order).
    cv_total = cv_total + ls_order-qty.
  ENDLOOP.
ENDFORM.

FORM show USING is_order TYPE ty_order.
  WRITE: / 'Order', is_order-id, 'qty', is_order-qty.
ENDFORM.
