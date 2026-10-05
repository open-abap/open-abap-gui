REPORT zgg_ex_150.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         fldate   TYPE d,
         seatsmax TYPE i,
         seatsocc TYPE i,
       END OF ty_flight.

CLASS lcl_cockpit DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS select_flights.
    CLASS-METHODS create_controls.
    CLASS-METHODS chart_xml
      RETURNING
        VALUE(rv_xml) TYPE string.
    CLASS-METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row.
ENDCLASS.

PARAMETERS p_carr TYPE c LENGTH 3 DEFAULT 'LH' OBLIGATORY.
PARAMETERS p_date TYPE d DEFAULT '20260801'.

DATA gt_all TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_splitter TYPE REF TO cl_gui_splitter_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_chart TYPE REF TO cl_gui_chart_engine.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_cockpit IMPLEMENTATION.
  METHOD select_flights.
    gt_all = VALUE #(
      ( carrid = 'LH' connid = '0400' fldate = '20260803' seatsmax = 280 seatsocc = 180 )
      ( carrid = 'LH' connid = '0402' fldate = '20260810' seatsmax = 280 seatsocc = 240 )
      ( carrid = 'LH' connid = '0400' fldate = '20260717' seatsmax = 280 seatsocc = 260 )
      ( carrid = 'UA' connid = '0941' fldate = '20260805' seatsmax = 300 seatsocc = 210 )
      ( carrid = 'UA' connid = '0945' fldate = '20260812' seatsmax = 300 seatsocc = 90 ) ).
    gt_flights = VALUE #( FOR ls_flight IN gt_all
                          WHERE ( carrid = p_carr AND fldate >= p_date ) ( ls_flight ) ).
  ENDMETHOD.

  METHOD create_controls.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_splitter
      EXPORTING
        parent  = go_container
        rows    = 1
        columns = 2.
    CREATE OBJECT go_grid
      EXPORTING
        i_parent      = go_splitter->get_container( row    = 1
                                                    column = 1 )
        i_appl_events = abap_true.
    gt_fieldcat = VALUE #(
      ( fieldname = 'CARRID' coltext = 'Airline' outputlen = 7 )
      ( fieldname = 'CONNID' coltext = 'Flight' outputlen = 6 )
      ( fieldname = 'FLDATE' coltext = 'Date' outputlen = 10 )
      ( fieldname = 'SEATSOCC' coltext = 'Occupied' outputlen = 8 do_sum = abap_true ) ).
    SET HANDLER on_double_click FOR go_grid.
    go_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = gt_flights
        it_fieldcatalog = gt_fieldcat ).
    CREATE OBJECT go_chart
      EXPORTING
        parent = go_splitter->get_container( row    = 1
                                             column = 2 ).
    go_chart->set_data( data = chart_xml( ) ).
    go_chart->set_customizing( data = |<SAPChartCustomizing version="1.1"><GlobalSettings><Defaults>|
                                   && |<ChartType>Columns</ChartType></Defaults></GlobalSettings><Elements>|
                                   && |<ChartElements><Title><Caption>Load factor in %</Caption></Title>|
                                   && |</ChartElements></Elements></SAPChartCustomizing>| ).
    go_chart->render( ).
  ENDMETHOD.

  METHOD chart_xml.
    DATA lv_values TYPE string.

    rv_xml = '<SimpleChartData><Categories>'.
    LOOP AT gt_flights INTO DATA(ls_flight).
      rv_xml = |{ rv_xml }<C>{ ls_flight-connid } { ls_flight-fldate DATE = ISO }</C>|.
      lv_values = |{ lv_values }<S>{ ls_flight-seatsocc * 100 DIV ls_flight-seatsmax }</S>|.
    ENDLOOP.
    rv_xml = |{ rv_xml }</Categories><Series label="Load factor">{ lv_values }</Series></SimpleChartData>|.
  ENDMETHOD.

  METHOD on_double_click.
    READ TABLE gt_flights INTO DATA(ls_flight) INDEX e_row-index.
    gv_state = |{ ls_flight-carrid } { ls_flight-connid }: { ls_flight-seatsocc } of { ls_flight-seatsmax } seats|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  lcl_cockpit=>select_flights( ).
  IF gt_flights IS INITIAL.
    MESSAGE 'No flights for this selection' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    lcl_cockpit=>create_controls( ).
    gv_state = |{ lines( gt_flights ) } flight(s) of { p_carr } from { p_date DATE = ISO }|.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CLEAR gv_ok_code.
ENDMODULE.
