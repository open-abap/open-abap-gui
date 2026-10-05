REPORT zgg_ex_089.

DATA gv_amount TYPE p LENGTH 8 DECIMALS 2 VALUE '42.50'.
DATA gv_date TYPE c LENGTH 10 VALUE '2026-08-30'.
DATA gv_zero TYPE i VALUE 0.
DATA gv_count TYPE i VALUE 123456789.

START-OF-SELECTION.
  WRITE: /(10) gv_amount,
          14(12) gv_date,
          28(8) gv_zero NO-ZERO,
          38(12) gv_count.
