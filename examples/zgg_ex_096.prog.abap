REPORT zgg_ex_096.

START-OF-SELECTION.
  SET PF-STATUS 'LIST'.
  WRITE / 'message list'.
  MESSAGE 'Saved successfully' TYPE 'S'.
  MESSAGE 'Review the selection' TYPE 'S' DISPLAY LIKE 'W'.

AT USER-COMMAND.
  IF sy-ucomm = 'MESSAGES'.
    MESSAGE 'Success message' TYPE 'S'.
    MESSAGE 'Warning message' TYPE 'S' DISPLAY LIKE 'W'.
    MESSAGE 'Error message' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
