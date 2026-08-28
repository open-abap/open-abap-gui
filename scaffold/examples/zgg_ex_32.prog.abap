REPORT zgg_ex_32.

TABLES zsflight.
SELECT-OPTIONS s_carr FOR zsflight-carrid.

AT SELECTION-SCREEN ON END OF s_carr.
  IF lines( s_carr ) > 5.
    MESSAGE 'at most five entries' TYPE 'E'.
  ENDIF.
