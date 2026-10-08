REPORT zgg_ex_138.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_rows TYPE lvc_t_row.
DATA gs_layout TYPE lvc_s_layo.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' seatsocc = 210 )
    ( carrid = 'AF' connid = '0010' seatsocc = 160 ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_grid = NEW #( i_parent = go_container ).
    gt_fieldcat = VALUE #(
      ( fieldname = 'CARRID' coltext = 'Airline' outputlen = 7 )
      ( fieldname = 'CONNID' coltext = 'Flight' outputlen = 6 )
      ( fieldname = 'SEATSOCC' coltext = 'Occupied' outputlen = 8 ) ).
    gs_layout-sel_mode = 'A'.
    go_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_flights
        it_fieldcatalog = gt_fieldcat ).
    gt_rows = VALUE #( ( index = 2 ) ).
    go_grid->set_selected_rows( it_index_rows = gt_rows ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SHOW'.
    go_grid->get_selected_rows( IMPORTING et_index_rows = gt_rows ).
    CLEAR gv_state.
    LOOP AT gt_rows INTO DATA(ls_row).
      READ TABLE gt_flights INTO DATA(ls_flight) INDEX ls_row-index.
      gv_state = |{ gv_state } { ls_flight-carrid } { ls_flight-connid }|.
    ENDLOOP.
    IF gv_state IS INITIAL.
      gv_state = 'No flight selected'.
    ELSE.
      gv_state = |Selected:{ gv_state }|.
    ENDIF.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
