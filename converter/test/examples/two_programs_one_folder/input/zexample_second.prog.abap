REPORT zexample_second.

DATA gv_text TYPE string.

START-OF-SELECTION.
  CALL METHOD zcl_example_shared=>describe
    EXPORTING
      iv_who  = `the second report`
    IMPORTING
      ev_text = gv_text.
  WRITE: / gv_text.
