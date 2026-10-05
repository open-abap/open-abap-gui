REPORT zgg_ex_095.

* Save to local file (%PC) in the List menu of the standard list status
* saves the list as the user chose: unconverted, as a spreadsheet or as
* HTML. The list processor does it; the program only writes the list.

TYPES: BEGIN OF ty_carrier,
         carrid   TYPE c LENGTH 3,
         carrname TYPE c LENGTH 20,
         currency TYPE c LENGTH 5,
       END OF ty_carrier.

DATA gt_carriers TYPE STANDARD TABLE OF ty_carrier WITH DEFAULT KEY.
DATA gs_carrier TYPE ty_carrier.

START-OF-SELECTION.
  gt_carriers = VALUE #(
    ( carrid = 'LH' carrname = 'Lufthansa' currency = 'EUR' )
    ( carrid = 'UA' carrname = 'United Airlines' currency = 'USD' )
    ( carrid = 'SQ' carrname = 'Singapore Airlines' currency = 'SGD' ) ).
  WRITE: / 'ID', 6 'Airline', 28 'Currency'.
  LOOP AT gt_carriers INTO gs_carrier.
    WRITE: / gs_carrier-carrid, 6 gs_carrier-carrname, 28 gs_carrier-currency.
  ENDLOOP.
