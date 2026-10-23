REPORT zgg_ex_182.

* A second work area of a database table, declared TABLES *dbtab.

TABLES: t100, *t100.

DATA gv_text LIKE *t100-text.

START-OF-SELECTION.
  CLEAR *t100.
  SELECT SINGLE * FROM *t100 WHERE arbgb = '00'.
  IF *t100-arbgb = '00'.
    gv_text = *t100-text.
    WRITE / gv_text.
  ENDIF.
  t100 = *t100.
  WRITE / t100-msgnr.
