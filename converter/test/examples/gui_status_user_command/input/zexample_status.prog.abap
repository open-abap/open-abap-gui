REPORT zexample_status.

DATA gv_count TYPE i.

START-OF-SELECTION.
  SET PF-STATUS 'LIST'.
  SET TITLEBAR 'MAIN' WITH 'Counter'.
  PERFORM show.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'ADD'.
      gv_count = gv_count + 1.
      PERFORM show.
    WHEN 'RESET'.
      CLEAR gv_count.
      PERFORM show.
  ENDCASE.

FORM show.
  WRITE: / 'Count:', gv_count.
ENDFORM.
