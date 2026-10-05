REPORT zgg_ex_083.

* Each double click opens the next list level: the airlines (the basic list,
* sy-lsind 0), the flights of one airline (1) and the bookings of one flight
* (2). HIDE keeps the key of each line; Back returns one level.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

TYPES: BEGIN OF ty_booking,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         customer TYPE c LENGTH 20,
         seats    TYPE i,
       END OF ty_booking.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_bookings TYPE STANDARD TABLE OF ty_booking WITH DEFAULT KEY.
DATA gs_flight TYPE ty_flight.
DATA gs_booking TYPE ty_booking.
DATA gv_carrid TYPE c LENGTH 3.
DATA gv_connid TYPE n LENGTH 4.

TOP-OF-PAGE.
  WRITE / 'Airlines'.
  ULINE.

TOP-OF-PAGE DURING LINE-SELECTION.
  CASE sy-lsind.
    WHEN 1.
      WRITE / |Flights of { gv_carrid }|.
    WHEN 2.
      WRITE / |Bookings of { gv_carrid } { gv_connid }|.
  ENDCASE.
  ULINE.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'LH' connid = '0402' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' ) ).
  gt_bookings = VALUE #(
    ( carrid = 'LH' connid = '0400' customer = 'Ada Lovelace' seats = 2 )
    ( carrid = 'LH' connid = '0400' customer = 'Grace Hopper' seats = 1 )
    ( carrid = 'LH' connid = '0402' customer = 'Alan Turing' seats = 3 )
    ( carrid = 'UA' connid = '0941' customer = 'Edsger Dijkstra' seats = 1 ) ).

  CLEAR gv_connid.
  gv_carrid = 'LH'.
  WRITE / 'LH Lufthansa'.
  HIDE gv_carrid.
  gv_carrid = 'UA'.
  WRITE / 'UA United Airlines'.
  HIDE gv_carrid.
  CLEAR gv_carrid.

AT LINE-SELECTION.
  CASE sy-lsind.
    WHEN 1.
      LOOP AT gt_flights INTO gs_flight WHERE carrid = gv_carrid.
        gv_connid = gs_flight-connid.
        WRITE: / gs_flight-connid, gs_flight-cityfrom, gs_flight-cityto.
        HIDE gv_connid.
      ENDLOOP.
    WHEN 2.
      LOOP AT gt_bookings INTO gs_booking WHERE carrid = gv_carrid AND connid = gv_connid.
        WRITE: / gs_booking-customer, gs_booking-seats.
      ENDLOOP.
      WRITE / |Chosen in list { sy-listi }, line { sy-lilli }|.
  ENDCASE.
