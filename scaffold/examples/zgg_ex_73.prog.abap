REPORT zgg_ex_73.

TABLES zsflight.
SELECT-OPTIONS s_mul FOR zsflight-carrid.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

START-OF-SELECTION.
  LOOP AT s_mul.
    WRITE: / s_mul-sign, s_mul-option, s_mul-low, s_mul-high.
  ENDLOOP.
