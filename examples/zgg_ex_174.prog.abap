REPORT zgg_ex_174.

TABLES t100.
SELECT-OPTIONS s_arbgb FOR t100-arbgb.

FORM run.
  " test it has header line
  s_arbgb-sign = 'I'.
  WRITE / 'hello'.
ENDFORM.

START-OF-SELECTION.
  PERFORM run.
