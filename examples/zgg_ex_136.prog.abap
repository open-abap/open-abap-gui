REPORT zgg_ex_136.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsmax TYPE i,
         seatsocc TYPE i,
       END OF ty_flight.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_data_changed FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed.
    CLASS-METHODS on_data_changed_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING e_modified et_good_cells.
ENDCLASS.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.
DATA gv_valid TYPE abap_bool.
DATA gv_total TYPE i.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_data_changed.
    DATA ls_flight TYPE ty_flight.
    DATA lv_seatsocc TYPE i.

    LOOP AT er_data_changed->mt_good_cells INTO DATA(ls_cell) WHERE fieldname = 'SEATSOCC'.
      READ TABLE gt_flights INTO ls_flight INDEX ls_cell-row_id.
      lv_seatsocc = ls_cell-value.
      IF lv_seatsocc > ls_flight-seatsmax.
        er_data_changed->add_protocol_entry(
          i_msgid     = '0K'
          i_msgty     = 'E'
          i_msgno     = '000'
          i_msgv1     = |Flight { ls_flight-carrid } { ls_flight-connid } has { ls_flight-seatsmax } seats|
          i_fieldname = ls_cell-fieldname
          i_row_id    = ls_cell-row_id ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD on_data_changed_finished.
    IF e_modified = abap_true.
      gv_state = |{ lines( et_good_cells ) } cell(s) changed|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' seatsmax = 300 seatsocc = 210 )
    ( carrid = 'AF' connid = '0010' seatsmax = 220 seatsocc = 160 ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_container.
    gt_fieldcat = VALUE #(
      ( fieldname = 'CARRID' coltext = 'Airline' key = abap_true outputlen = 7 )
      ( fieldname = 'CONNID' coltext = 'Flight' outputlen = 6 )
      ( fieldname = 'SEATSMAX' coltext = 'Capacity' outputlen = 8 )
      ( fieldname = 'SEATSOCC' coltext = 'Occupied' edit = abap_true outputlen = 8 ) ).
    SET HANDLER lcl_handler=>on_data_changed FOR go_grid.
    SET HANDLER lcl_handler=>on_data_changed_finished FOR go_grid.
    go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_enter ).
    go_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = gt_flights
        it_fieldcatalog = gt_fieldcat ).
    go_grid->set_ready_for_input( 1 ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SAVE'.
    go_grid->check_changed_data( IMPORTING e_valid = gv_valid ).
    IF gv_valid = abap_true.
      gv_total = REDUCE i( INIT n = 0 FOR ls_flight IN gt_flights NEXT n = n + ls_flight-seatsocc ).
      gv_state = |Saved, { gv_total } seats occupied|.
    ELSE.
      gv_state = 'Correct the marked cells first'.
    ENDIF.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
