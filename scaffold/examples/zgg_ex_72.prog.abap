REPORT zgg_ex_72.

TABLES zsflight.
SELECT-OPTIONS s_car FOR zsflight-carrid NO-EXTENSION.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

START-OF-SELECTION.
  LOOP AT s_car.
    WRITE: / s_car-sign, s_car-option, s_car-low, s_car-high.
  ENDLOOP.
