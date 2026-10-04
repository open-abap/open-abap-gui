REPORT zgg_ex_145.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA go_alv TYPE REF TO cl_salv_table.
DATA gx_msg TYPE REF TO cx_salv_msg.
DATA gx_error TYPE REF TO cx_salv_error.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' seatsocc = 210 )
    ( carrid = 'LH' connid = '0402' seatsocc = 240 )
    ( carrid = 'AF' connid = '0010' seatsocc = 160 )
    ( carrid = 'UA' connid = '0945' seatsocc = 90 ) ).
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_alv
        CHANGING
          t_table      = gt_flights ).
    CATCH cx_salv_msg INTO gx_msg.
      MESSAGE gx_msg TYPE 'E'.
  ENDTRY.
  go_alv->get_display_settings( )->set_list_header( 'Occupied seats per airline' ).
  TRY.
      go_alv->get_sorts( )->add_sort( columnname = 'CARRID'
                                      subtotal   = abap_true ).
      go_alv->get_filters( )->add_filter( columnname = 'SEATSOCC'
                                          sign       = 'I'
                                          option     = 'GE'
                                          low        = '100' ).
      go_alv->get_aggregations( )->add_aggregation( 'SEATSOCC' ).
    CATCH cx_salv_error INTO gx_error.
      MESSAGE gx_error TYPE 'E'.
  ENDTRY.
  go_alv->display( ).
