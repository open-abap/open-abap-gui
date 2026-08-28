REPORT zgg_ex_53.

START-OF-SELECTION.
  IF sy-subrc = 0.
    SUBMIT zgg_ex_01.
  ELSE.
    WRITE 'never reached'.
  ENDIF.
