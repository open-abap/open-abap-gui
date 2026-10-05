REPORT zgg_ex_088.

DATA gv_active TYPE c LENGTH 1 VALUE 'X'.
DATA gv_phone TYPE c LENGTH 1 VALUE '!'.

START-OF-SELECTION.
  WRITE / icon_green_light AS ICON QUICKINFO 'Icon & <safe>'.
  WRITE gv_phone AS SYMBOL QUICKINFO 'Symbol'.
  WRITE gv_active AS CHECKBOX QUICKINFO 'Active'.
