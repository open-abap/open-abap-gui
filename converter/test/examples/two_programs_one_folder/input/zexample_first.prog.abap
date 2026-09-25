REPORT zexample_first.

DATA gv_text TYPE string.

START-OF-SELECTION.
  zcl_example_shared=>describe(
    EXPORTING iv_who  = `the first report`
    IMPORTING ev_text = gv_text ).
  WRITE: / gv_text.
