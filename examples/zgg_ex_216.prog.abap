REPORT zgg_ex_216.

* A report may give a length to a type whose length is fixed; it is
* ignored. A class rejects it, so the converted class has none.

TYPES ty_time(6) TYPE t.

CONSTANTS gc_start(8) TYPE d VALUE '20240101'.

DATA gv_count(10) TYPE i.
DATA gv_name(10) TYPE c.
DATA gv_amount(8) TYPE p DECIMALS 2.
DATA: BEGIN OF gs_line,
        id(4)    TYPE i,
        text(20) TYPE c,
      END OF gs_line.

FORM show.
  DATA lv_calls(10) TYPE i.
  DATA lv_time TYPE ty_time VALUE '120000'.
  lv_calls = lv_calls + 1.
  WRITE: / lv_calls, lv_time.
ENDFORM.

START-OF-SELECTION.
  gv_count = 3.
  gv_name = 'Lengths'.
  gv_amount = '12.50'.
  gs_line-id = gv_count.
  gs_line-text = gv_name.
  WRITE: / gs_line-text, gs_line-id, gv_amount, gc_start.
  PERFORM show.
