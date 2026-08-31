REPORT zgg_ex_85.
START-OF-SELECTION.
  SET PF-STATUS 'LIST'.
  WRITE / 'before refresh'.
AT USER-COMMAND.
  IF sy-ucomm = 'REFRESH'.
    WRITE / 'after refresh'.
  ENDIF.
