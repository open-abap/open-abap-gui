REPORT zgg_ex_085.

DATA gv_refreshes TYPE i.

START-OF-SELECTION.
  SET PF-STATUS 'LIST'.
  WRITE / 'before refresh'.

AT USER-COMMAND.
  IF sy-ucomm = 'REFRESH'.
    gv_refreshes = gv_refreshes + 1.
    WRITE / 'refreshed from server state'.
    WRITE / |refresh count { gv_refreshes }|.
  ENDIF.
