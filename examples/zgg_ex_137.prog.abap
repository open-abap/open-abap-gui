REPORT zgg_ex_137.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_sort TYPE lvc_t_sort.
DATA gt_filter TYPE lvc_t_filt.
DATA gt_filtered TYPE lvc_t_fidx.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' seatsocc = 210 )
    ( carrid = 'LH' connid = '0402' seatsocc = 240 )
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
    gt_sort = VALUE #( ( spos = 1 fieldname = 'SEATSOCC' down = abap_true ) ).
    go_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = gt_flights
        it_fieldcatalog = gt_fieldcat
        it_sort         = gt_sort
        it_filter       = gt_filter ).
    gv_state = 'Sorted by occupied seats, descending'.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'SORT'.
      go_grid->get_sort_criteria( IMPORTING et_sort = gt_sort ).
      LOOP AT gt_sort ASSIGNING FIELD-SYMBOL(<ls_sort>).
        <ls_sort>-up = <ls_sort>-down.
        <ls_sort>-down = xsdbool( <ls_sort>-up = abap_false ).
        gv_state = COND #( WHEN <ls_sort>-down = abap_true
                           THEN 'Sorted by occupied seats, descending'
                           ELSE 'Sorted by occupied seats, ascending' ).
      ENDLOOP.
      go_grid->set_sort_criteria( gt_sort ).
      go_grid->refresh_table_display( ).
    WHEN 'FILTER'.
      gt_filter = VALUE #( ( fieldname = 'CARRID' sign = 'I' option = 'EQ' low = 'LH' ) ).
      go_grid->set_filter_criteria( gt_filter ).
      go_grid->refresh_table_display( ).
      go_grid->get_filtered_entries( IMPORTING et_filtered_entries = gt_filtered ).
      gv_state = |Airline LH, { lines( gt_filtered ) } flight(s) filtered out|.
    WHEN 'NOFILTER'.
      CLEAR gt_filter.
      go_grid->set_filter_criteria( gt_filter ).
      go_grid->refresh_table_display( ).
      gv_state = 'All airlines'.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
