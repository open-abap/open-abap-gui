REPORT zgg_ex_157.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
         seatsmax TYPE i,
         seatsocc TYPE i,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gs_layout TYPE lvc_s_layo.
DATA gs_variant TYPE disvariant.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_layout TYPE c LENGTH 12.
DATA gv_layout_text TYPE c LENGTH 40.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' seatsmax = 280 seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' seatsmax = 300 seatsocc = 210 )
    ( carrid = 'AF' connid = '0010' cityfrom = 'Paris' cityto = 'New York' seatsmax = 220 seatsocc = 160 ) ).
  gt_fieldcat = VALUE #(
    ( fieldname = 'CARRID' coltext = 'Airline' outputlen = 7 )
    ( fieldname = 'CONNID' coltext = 'Flight' outputlen = 6 )
    ( fieldname = 'CITYFROM' coltext = 'From' outputlen = 15 )
    ( fieldname = 'CITYTO' coltext = 'To' outputlen = 15 )
    ( fieldname = 'SEATSMAX' coltext = 'Capacity' outputlen = 8 )
    ( fieldname = 'SEATSOCC' coltext = 'Occupied' outputlen = 8 ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_GRID' ).
    go_grid = NEW #( i_parent = go_container ).
    gs_variant-report = sy-repid.
    gs_variant-handle = 'FLTS'.
    gs_layout-grid_title = 'Flights'.
    go_grid->set_table_for_first_display(
      EXPORTING
        is_variant      = gs_variant
        i_save          = 'A'
        i_default       = abap_true
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_flights
        it_fieldcatalog = gt_fieldcat ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SHOW'.
    go_grid->get_variant( IMPORTING es_variant = gs_variant ).
    gv_layout = gs_variant-variant.
    gv_layout_text = gs_variant-text.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
