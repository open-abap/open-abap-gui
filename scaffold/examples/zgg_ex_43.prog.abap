REPORT zgg_ex_43.

DATA gv_id TYPE i.

START-OF-SELECTION.
  DO 3 TIMES.
    gv_id = sy-index.
    WRITE / gv_id.
    HIDE gv_id.
  ENDDO.

AT LINE-SELECTION.
  WRITE / gv_id.
