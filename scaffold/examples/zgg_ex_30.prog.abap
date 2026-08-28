REPORT zgg_ex_30.

PARAMETERS p_n TYPE i.

AT SELECTION-SCREEN.
  IF p_n < 0.
    MESSAGE 'must not be negative' TYPE 'E'.
  ENDIF.
