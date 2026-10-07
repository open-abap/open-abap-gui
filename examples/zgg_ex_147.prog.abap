REPORT zgg_ex_147.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsocc TYPE i,
       END OF ty_flight.

* The SALV events are system events: PAI does not run unless a handler sets
* an OK code, so the handlers ask for PAI to show their result.
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
    CLASS-METHODS on_link_click FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row.
ENDCLASS.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_alv TYPE REF TO cl_salv_table.
DATA go_column TYPE REF TO cl_salv_column_table.
DATA gt_rows TYPE salv_t_row.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    READ TABLE gt_flights INTO DATA(ls_flight) INDEX row.
    gv_state = |Double click on { ls_flight-carrid } { ls_flight-connid }, column { column }|.
    cl_gui_cfw=>set_new_ok_code( 'EVENT' ).
  ENDMETHOD.

  METHOD on_link_click.
    READ TABLE gt_flights INTO DATA(ls_flight) INDEX row.
    gv_state = |Airline { ls_flight-carrid } chosen|.
    cl_gui_cfw=>set_new_ok_code( 'EVENT' ).
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
    TRY.
        cl_salv_table=>factory(
          EXPORTING
            r_container  = go_container
          IMPORTING
            r_salv_table = go_alv
          CHANGING
            t_table      = gt_flights ).
        go_column ?= go_alv->get_columns( )->get_column( 'CARRID' ).
        go_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
      CATCH cx_salv_error.
        RETURN.
    ENDTRY.
    go_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).
    SET HANDLER lcl_handler=>on_double_click FOR go_alv->get_event( ).
    SET HANDLER lcl_handler=>on_link_click FOR go_alv->get_event( ).
    go_alv->display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SHOW'.
    gt_rows = go_alv->get_selections( )->get_selected_rows( ).
    gv_state = |{ lines( gt_rows ) } flight(s) selected|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
