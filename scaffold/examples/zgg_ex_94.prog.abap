REPORT zgg_ex_94.
START-OF-SELECTION.
  WRITE / 'interactive list'.
AT USER-COMMAND.
  IF sy-ucomm = 'PRINT_VIEW'.
    WRITE / 'PRINT VIEW'.
  ENDIF.
