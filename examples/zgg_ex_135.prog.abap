REPORT zgg_ex_135.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         carrname TYPE c LENGTH 20,
         connid   TYPE n LENGTH 4,
         seatsmax TYPE i,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gs_layout TYPE lvc_s_layo.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' carrname = 'Lufthansa' connid = '0400' seatsmax = 280 seatsocc = 180 )
    ( carrid = 'UA' carrname = 'United Airlines' connid = '0941' seatsmax = 300 seatsocc = 210 )
    ( carrid = 'AF' carrname = 'Air France' connid = '0010' seatsmax = 220 seatsocc = 160 ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_grid = NEW #( i_parent = go_container ).
    PERFORM build_fieldcat.
    gs_layout-zebra = abap_true.
    gs_layout-grid_title = 'Flight capacity'.
    go_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_flights
        it_fieldcatalog = gt_fieldcat ).
    gv_state = |{ lines( gt_flights ) } flights, { lines( gt_fieldcat ) } columns|.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'HIDE_MAX'.
      go_grid->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = gt_fieldcat ).
      LOOP AT gt_fieldcat ASSIGNING FIELD-SYMBOL(<ls_fieldcat>) WHERE fieldname = 'SEATSMAX'.
        <ls_fieldcat>-no_out = xsdbool( <ls_fieldcat>-no_out = abap_false ).
        gv_state = COND #( WHEN <ls_fieldcat>-no_out = abap_true THEN 'Capacity column hidden' ELSE 'Capacity column shown' ).
      ENDLOOP.
      go_grid->set_frontend_fieldcatalog( gt_fieldcat ).
      go_grid->refresh_table_display( ).
    WHEN 'ZEBRA'.
      go_grid->get_frontend_layout( IMPORTING es_layout = gs_layout ).
      gs_layout-zebra = xsdbool( gs_layout-zebra = abap_false ).
      go_grid->set_frontend_layout( gs_layout ).
      go_grid->refresh_table_display( ).
      gv_state = COND #( WHEN gs_layout-zebra = abap_true THEN 'Striped rows' ELSE 'Plain rows' ).
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.

FORM build_fieldcat.
  gt_fieldcat = VALUE #(
    ( fieldname = 'CARRID' col_pos = 1 coltext = 'Airline' key = abap_true outputlen = 7 )
    ( fieldname = 'CARRNAME' col_pos = 2 coltext = 'Name' outputlen = 20 emphasize = 'C300' )
    ( fieldname = 'CONNID' col_pos = 3 coltext = 'Flight' outputlen = 6 )
    ( fieldname = 'SEATSMAX' col_pos = 4 coltext = 'Capacity' do_sum = abap_true outputlen = 8 )
    ( fieldname = 'SEATSOCC' col_pos = 5 coltext = 'Occupied' do_sum = abap_true outputlen = 8 ) ).
ENDFORM.
