REPORT zexample_forms.

TYPES: BEGIN OF ty_item,
         name TYPE string,
         qty  TYPE i,
       END OF ty_item.
TYPES ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

DATA gt_items TYPE ty_items.
DATA gv_total TYPE i.

START-OF-SELECTION.
  PERFORM fill_items.
  PERFORM sum_items USING gt_items CHANGING gv_total.
  PERFORM print_total USING gv_total.

FORM fill_items.
  APPEND VALUE #( name = `Apple` qty = 3 ) TO gt_items.
  APPEND VALUE #( name = `Pear` qty = 4 ) TO gt_items.
ENDFORM.

FORM sum_items USING it_items TYPE ty_items CHANGING cv_total TYPE i.
  DATA ls_item TYPE ty_item.
  CLEAR cv_total.
  LOOP AT it_items INTO ls_item.
    cv_total = cv_total + ls_item-qty.
  ENDLOOP.
ENDFORM.

FORM print_total USING iv_total TYPE i.
  WRITE: / 'Total quantity:', iv_total.
ENDFORM.
