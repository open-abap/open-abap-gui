REPORT zgg_ex_187.

* Data objects whose start value is the program name, sy-repid.

DATA gv_prog TYPE progname VALUE sy-repid.

FORM get_prog.
  DATA lv_prog TYPE progname VALUE sy-repid.
  WRITE: / lv_prog, gv_prog.
ENDFORM.

START-OF-SELECTION.
  PERFORM get_prog.
