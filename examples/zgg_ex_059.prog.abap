REPORT zgg_ex_059.

* The application toolbar of the status: Refresh, a separator, then the
* functions that change the booking, each with its icon and text.

DATA gv_seats TYPE i VALUE 2.

START-OF-SELECTION.
  SET PF-STATUS 'SEATS'.
  PERFORM show.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'ADD'.
      gv_seats = gv_seats + 1.
    WHEN 'REMOVE'.
      IF gv_seats > 0.
        gv_seats = gv_seats - 1.
      ENDIF.
  ENDCASE.
  PERFORM show.

FORM show.
  WRITE / |Ada Lovelace, flight LH 0400: { gv_seats } seats|.
ENDFORM.
