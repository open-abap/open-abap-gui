REPORT zgg_ex_094.
START-OF-SELECTION.
  WRITE / 'interactive list'.
AT USER-COMMAND.
  IF sy-ucomm = 'PRINT_VIEW'.
    WRITE / 'PRINT VIEW'.
  ENDIF.
