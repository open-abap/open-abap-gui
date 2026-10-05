REPORT zgg_ex_158.

TYPES: BEGIN OF ty_carrier,
         expand   TYPE c LENGTH 1,
         carrid   TYPE c LENGTH 3,
         carrname TYPE c LENGTH 20,
       END OF ty_carrier.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_carriers TYPE STANDARD TABLE OF ty_carrier WITH DEFAULT KEY.
DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_binding TYPE salv_t_hierseq_binding.
DATA go_hierseq TYPE REF TO cl_salv_hierseq_table.
DATA go_columns TYPE REF TO cl_salv_columns_hierseq.
DATA go_column TYPE REF TO cl_salv_column.
DATA gx_data TYPE REF TO cx_salv_data_error.
DATA gx_not_found TYPE REF TO cx_salv_not_found.

START-OF-SELECTION.
  gt_carriers = VALUE #(
    ( expand = 'X' carrid = 'LH' carrname = 'Lufthansa' )
    ( expand = 'X' carrid = 'UA' carrname = 'United Airlines' ) ).
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' seatsocc = 180 )
    ( carrid = 'LH' connid = '0402' cityfrom = 'Frankfurt' cityto = 'New York' seatsocc = 240 )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' seatsocc = 210 ) ).
  gt_binding = VALUE #( ( master = 'CARRID' slave = 'CARRID' ) ).

  TRY.
      cl_salv_hierseq_table=>factory(
        EXPORTING
          t_binding_level1_level2 = gt_binding
        IMPORTING
          r_hierseq               = go_hierseq
        CHANGING
          t_table_level1          = gt_carriers
          t_table_level2          = gt_flights ).
    CATCH cx_salv_data_error INTO gx_data.
      MESSAGE gx_data TYPE 'E'.
    CATCH cx_salv_not_found INTO gx_not_found.
      MESSAGE gx_not_found TYPE 'E'.
  ENDTRY.

  go_hierseq->get_functions( )->set_all( abap_true ).
  go_hierseq->get_display_settings( )->set_list_header( 'Flights by airline' ).

  TRY.
      go_columns = go_hierseq->get_columns( 1 ).
      go_columns->set_expand_column( 'EXPAND' ).
      go_column = go_columns->get_column( 'CARRID' ).
      go_column->set_long_text( 'Airline' ).
      go_column = go_columns->get_column( 'CARRNAME' ).
      go_column->set_long_text( 'Name' ).

      go_columns = go_hierseq->get_columns( 2 ).
      go_column = go_columns->get_column( 'CARRID' ).
      go_column->set_technical( abap_true ).
      go_column = go_columns->get_column( 'CONNID' ).
      go_column->set_long_text( 'Flight' ).
      go_column = go_columns->get_column( 'CITYFROM' ).
      go_column->set_long_text( 'From' ).
      go_column = go_columns->get_column( 'CITYTO' ).
      go_column->set_long_text( 'To' ).
      go_column = go_columns->get_column( 'SEATSOCC' ).
      go_column->set_long_text( 'Occupied' ).

      go_hierseq->get_aggregations( 2 )->add_aggregation( 'SEATSOCC' ).
    CATCH cx_salv_not_found INTO gx_not_found.
      MESSAGE gx_not_found TYPE 'E'.
    CATCH cx_salv_data_error INTO gx_data.
      MESSAGE gx_data TYPE 'E'.
  ENDTRY.

  go_hierseq->display( ).
