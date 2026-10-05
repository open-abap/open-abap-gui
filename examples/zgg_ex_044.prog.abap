REPORT zgg_ex_044.

* The status LIST serves several booking reports. This one only displays,
* so it excludes Delete: the function is not offered, and its code is
* refused.

DATA gv_refreshed TYPE i.

START-OF-SELECTION.
  SET PF-STATUS 'LIST' EXCLUDING 'DEL'.
  WRITE / 'Bookings of flight LH 0400'.
  WRITE / 'Ada Lovelace     2 seats'.
  WRITE / 'Grace Hopper     1 seat'.

AT USER-COMMAND.
  IF sy-ucomm = 'REFR'.
    gv_refreshed = gv_refreshed + 1.
    WRITE / |Bookings of flight LH 0400, refreshed { gv_refreshed } times|.
  ENDIF.
