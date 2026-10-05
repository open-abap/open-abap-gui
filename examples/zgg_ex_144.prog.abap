REPORT zgg_ex_144.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA go_alv TYPE REF TO cl_salv_table.
DATA go_column TYPE REF TO cl_salv_column.
DATA gx_msg TYPE REF TO cx_salv_msg.
DATA gx_not_found TYPE REF TO cx_salv_not_found.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' seatsocc = 210 )
    ( carrid = 'AF' connid = '0010' cityfrom = 'Paris' cityto = 'New York' seatsocc = 160 ) ).
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_alv
        CHANGING
          t_table      = gt_flights ).
    CATCH cx_salv_msg INTO gx_msg.
      MESSAGE gx_msg TYPE 'E'.
  ENDTRY.
  go_alv->get_functions( )->set_all( abap_true ).
  go_alv->get_columns( )->set_optimize( abap_true ).
  go_alv->get_display_settings( )->set_list_header( 'Flights' ).
  go_alv->get_display_settings( )->set_striped_pattern( abap_true ).
  TRY.
      go_column = go_alv->get_columns( )->get_column( 'CARRID' ).
      go_column->set_long_text( 'Airline' ).
      go_column = go_alv->get_columns( )->get_column( 'CONNID' ).
      go_column->set_long_text( 'Flight' ).
      go_column = go_alv->get_columns( )->get_column( 'CITYFROM' ).
      go_column->set_long_text( 'From' ).
      go_column = go_alv->get_columns( )->get_column( 'CITYTO' ).
      go_column->set_long_text( 'To' ).
      go_column = go_alv->get_columns( )->get_column( 'SEATSOCC' ).
      go_column->set_long_text( 'Occupied' ).
    CATCH cx_salv_not_found INTO gx_not_found.
      MESSAGE gx_not_found TYPE 'E'.
  ENDTRY.
  go_alv->display( ).
