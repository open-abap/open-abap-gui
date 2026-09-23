REPORT zgg_ex_053.

START-OF-SELECTION.
  IF sy-subrc = 0.
    SUBMIT zgg_ex_001.
  ELSE.
    WRITE 'never reached'.
  ENDIF.
