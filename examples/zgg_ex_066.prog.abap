REPORT zgg_ex_066.

START-OF-SELECTION.
  SET PF-STATUS 'SHELL66'.
  WRITE 'hostile Unicode shell text'.

AT USER-COMMAND.
  IF sy-ucomm = 'RUN66'.
    WRITE / 'accepted hostile'.
  ENDIF.
