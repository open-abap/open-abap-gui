REPORT zgg_ex_047.

DATA gv_field TYPE c LENGTH 30.
DATA gv_line  TYPE i.

AT LINE-SELECTION.
  GET CURSOR FIELD gv_field LINE gv_line.
  WRITE: / gv_field, gv_line.
