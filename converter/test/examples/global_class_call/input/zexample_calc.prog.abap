REPORT zexample_calc.

TABLES t100.

PARAMETERS p_count TYPE i DEFAULT 3.

DATA gv_total TYPE i.

START-OF-SELECTION.
  zcl_example_math=>sum_to(
    EXPORTING iv_count = p_count
    RECEIVING rv_total = gv_total ).
  WRITE: / 'Sum of 1 to', p_count, 'is', gv_total.
