REPORT zgg_ex_139.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsocc TYPE i,
       END OF ty_flight.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object.
    CLASS-METHODS on_user_command FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
    CLASS-METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    CLASS-METHODS on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id.
ENDCLASS.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_toolbar.
    APPEND VALUE #( butn_type = cntb_btype_sep ) TO e_object->mt_toolbar.
    APPEND VALUE #( function  = 'DETAILS'
                    icon      = icon_detail
                    quickinfo = 'Show flight details'
                    text      = 'Details' ) TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD on_user_command.
    DATA lt_rows TYPE lvc_t_row.

    IF e_ucomm = 'DETAILS'.
      go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
      READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
      IF sy-subrc <> 0.
        gv_state = 'Select a flight first'.
        RETURN.
      ENDIF.
      READ TABLE gt_flights INTO DATA(ls_flight) INDEX ls_row-index.
      gv_state = |Details of { ls_flight-carrid } { ls_flight-connid }: { ls_flight-seatsocc } seats|.
    ENDIF.
  ENDMETHOD.

  METHOD on_double_click.
    READ TABLE gt_flights INTO DATA(ls_flight) INDEX e_row-index.
    gv_state = |Double click on { ls_flight-carrid } { ls_flight-connid }, column { e_column-fieldname }|.
  ENDMETHOD.

  METHOD on_hotspot_click.
    READ TABLE gt_flights INTO DATA(ls_flight) INDEX e_row_id-index.
    gv_state = |Airline { ls_flight-carrid } chosen|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' seatsocc = 210 )
    ( carrid = 'AF' connid = '0010' seatsocc = 160 ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_grid = NEW #( i_parent      = go_container
                     i_appl_events = abap_true ).
    gt_fieldcat = VALUE #(
      ( fieldname = 'CARRID' coltext = 'Airline' hotspot = abap_true outputlen = 7 )
      ( fieldname = 'CONNID' coltext = 'Flight' outputlen = 6 )
      ( fieldname = 'SEATSOCC' coltext = 'Occupied' outputlen = 8 ) ).
    SET HANDLER lcl_handler=>on_toolbar FOR go_grid.
    SET HANDLER lcl_handler=>on_user_command FOR go_grid.
    SET HANDLER lcl_handler=>on_double_click FOR go_grid.
    SET HANDLER lcl_handler=>on_hotspot_click FOR go_grid.
    go_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = gt_flights
        it_fieldcatalog = gt_fieldcat ).
    gv_state = 'Use the Details button, a hotspot or a double click'.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CLEAR gv_ok_code.
ENDMODULE.
