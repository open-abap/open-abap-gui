REPORT zgg_ex_085.

* Refresh writes the free seats as a detail list. It sets sy-lsind to 1, so
* each refresh replaces that list instead of opening one more level, and Back
* goes straight to the basic list.

DATA gv_refreshes TYPE i.
DATA gv_seats TYPE i VALUE 12.

START-OF-SELECTION.
  SET PF-STATUS 'LIST'.
  WRITE / 'Flight LH 0400, Frankfurt to New York'.

AT USER-COMMAND.
  IF sy-ucomm = 'REFRESH'.
    sy-lsind = 1.
    gv_refreshes = gv_refreshes + 1.
    WRITE / |Free seats { gv_seats - gv_refreshes }|.
    WRITE / |Refreshed { gv_refreshes } times|.
  ENDIF.
