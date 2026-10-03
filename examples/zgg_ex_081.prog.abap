REPORT zgg_ex_081.

PARAMETERS p_good TYPE c LENGTH 20.
PARAMETERS p_bad TYPE c LENGTH 20 OBLIGATORY.

AT SELECTION-SCREEN ON p_bad.
  IF p_bad = 'bad'.
    MESSAGE 'Failing value rejected' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  WRITE p_good.
  WRITE / p_bad.
