REPORT zgg_ex_084.

DATA gv_row TYPE c LENGTH 1.
DATA gv_secret TYPE string.

START-OF-SELECTION.
  gv_row = 'A'.
  gv_secret = 'alpha'.
  WRITE / 'Repeated row'.
  HIDE: gv_row, gv_secret.
  gv_row = 'B'.
  gv_secret = 'bravo'.
  WRITE / 'Repeated row'.
  HIDE: gv_row, gv_secret.
  CLEAR: gv_row, gv_secret.

AT LINE-SELECTION.
  IF gv_secret IS NOT INITIAL.
    WRITE / |selected { gv_secret }|.
  ENDIF.
