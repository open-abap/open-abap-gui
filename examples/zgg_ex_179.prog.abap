REPORT zgg_ex_179.

* A type whose component is typed LIKE a component of a TABLES work area.

TABLES t100.

TYPES: BEGIN OF ty_row,
         msgnr LIKE t100-msgnr,
         text  LIKE t100-text,
       END OF ty_row.

DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.

START-OF-SELECTION.
  APPEND VALUE #( msgnr = '001' text = 'First' ) TO gt_rows.
  LOOP AT gt_rows INTO DATA(gs_row).
    WRITE: / gs_row-msgnr, gs_row-text.
  ENDLOOP.
