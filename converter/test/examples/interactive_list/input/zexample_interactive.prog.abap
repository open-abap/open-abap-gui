REPORT zexample_interactive NO STANDARD PAGE HEADING LINE-SIZE 60.

TYPES: BEGIN OF ty_row,
         id   TYPE i,
         name TYPE string,
       END OF ty_row.

DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
DATA gs_row TYPE ty_row.

START-OF-SELECTION.
  gt_rows = VALUE #( ( id = 1 name = `Alpha` ) ( id = 2 name = `Beta` ) ).
  LOOP AT gt_rows INTO gs_row.
    WRITE: / gs_row-id, gs_row-name HOTSPOT.
    HIDE gs_row-id.
  ENDLOOP.

TOP-OF-PAGE.
  WRITE: / 'Rows'.
  ULINE.

AT LINE-SELECTION.
  WRITE: / 'Selected row', gs_row-id, 'at list level', sy-lsind.

TOP-OF-PAGE DURING LINE-SELECTION.
  WRITE: / 'Details'.
