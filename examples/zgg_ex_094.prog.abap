REPORT zgg_ex_094.

* The program's own status keeps the list processor's Print (PRI), which
* the program is not called for; its own function Total reaches
* AT USER-COMMAND.

TYPES: BEGIN OF ty_booking,
         customer TYPE c LENGTH 20,
         seats    TYPE i,
       END OF ty_booking.

DATA gt_bookings TYPE STANDARD TABLE OF ty_booking WITH DEFAULT KEY.
DATA gs_booking TYPE ty_booking.
DATA gv_seats TYPE i.

START-OF-SELECTION.
  SET PF-STATUS 'LIST'.
  gt_bookings = VALUE #(
    ( customer = 'Ada Lovelace' seats = 2 )
    ( customer = 'Grace Hopper' seats = 3 )
    ( customer = 'Alan Turing' seats = 1 ) ).
  WRITE: / 'Customer', 24 'Seats'.
  ULINE.
  LOOP AT gt_bookings INTO gs_booking.
    WRITE: / gs_booking-customer, 24 gs_booking-seats.
  ENDLOOP.

AT USER-COMMAND.
  IF sy-ucomm = 'TOTAL'.
    CLEAR gv_seats.
    LOOP AT gt_bookings INTO gs_booking.
      gv_seats = gv_seats + gs_booking-seats.
    ENDLOOP.
    WRITE: / 'Seats booked', 24 gv_seats.
  ENDIF.
