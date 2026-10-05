REPORT zgg_ex_032.

* AT SELECTION-SCREEN ON END OF checks all entries of the select-option at
* once, after the multiple selection.

TABLES zsflight.
SELECT-OPTIONS s_carr FOR zsflight-carrid.

AT SELECTION-SCREEN ON END OF s_carr.
  IF lines( s_carr ) > 5.
    MESSAGE 'at most five entries' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  WRITE / |{ lines( s_carr ) } airline entries chosen|.
