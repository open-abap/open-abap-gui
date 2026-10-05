REPORT zgg_ex_146.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA go_alv TYPE REF TO cl_salv_table.
DATA go_top TYPE REF TO cl_salv_form_layout_grid.
DATA go_end TYPE REF TO cl_salv_form_layout_flow.
DATA go_label TYPE REF TO cl_salv_form_label.
DATA gx_msg TYPE REF TO cx_salv_msg.
DATA gv_total TYPE i.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' seatsocc = 210 )
    ( carrid = 'AF' connid = '0010' seatsocc = 160 ) ).
  gv_total = REDUCE i( INIT n = 0 FOR ls_flight IN gt_flights NEXT n = n + ls_flight-seatsocc ).
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_alv
        CHANGING
          t_table      = gt_flights ).
    CATCH cx_salv_msg INTO gx_msg.
      MESSAGE gx_msg TYPE 'E'.
  ENDTRY.

  CREATE OBJECT go_top.
  go_top->create_header_information( row     = 1
                                     column  = 1
                                     colspan = 2
                                     text    = 'Flight capacity report' ).
  go_label = go_top->create_label( row    = 2
                                   column = 1
                                   text   = 'Flights:' ).
  go_label->set_label_for( go_top->create_text( row    = 2
                                                column = 2
                                                text   = lines( gt_flights ) ) ).
  go_top->create_label( row    = 3
                        column = 1
                        text   = 'Occupied seats:' ).
  go_top->create_text( row    = 3
                       column = 2
                       text   = gv_total ).
  go_alv->set_top_of_list( go_top ).

  CREATE OBJECT go_end.
  go_end->create_text( text = 'End of report' ).
  go_alv->set_end_of_list( go_end ).
  go_alv->display( ).
