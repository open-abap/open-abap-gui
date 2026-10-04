REPORT zgg_ex_149.

TYPES: BEGIN OF ty_month,
         month    TYPE c LENGTH 10,
         seatsmax TYPE i,
         seatsocc TYPE i,
       END OF ty_month.

CLASS lcl_chart DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS data_xml
      RETURNING
        VALUE(rv_xml) TYPE string.
ENDCLASS.

DATA gt_months TYPE STANDARD TABLE OF ty_month WITH DEFAULT KEY.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_chart TYPE REF TO cl_gui_chart_engine.
DATA gv_chart_type TYPE string VALUE 'Lines'.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_chart IMPLEMENTATION.
  METHOD data_xml.
    DATA lv_capacity TYPE string.
    DATA lv_occupied TYPE string.

    rv_xml = '<?xml version="1.0" encoding="utf-8"?><SimpleChartData><Categories>'.
    LOOP AT gt_months INTO DATA(ls_month).
      rv_xml = |{ rv_xml }<C>{ ls_month-month }</C>|.
      lv_capacity = |{ lv_capacity }<S>{ ls_month-seatsmax }</S>|.
      lv_occupied = |{ lv_occupied }<S>{ ls_month-seatsocc }</S>|.
    ENDLOOP.
    rv_xml = |{ rv_xml }</Categories>|
          && |<Series label="Capacity">{ lv_capacity }</Series>|
          && |<Series label="Occupied">{ lv_occupied }</Series></SimpleChartData>|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  gt_months = VALUE #(
    ( month = 'June' seatsmax = 800 seatsocc = 610 )
    ( month = 'July' seatsmax = 800 seatsocc = 720 )
    ( month = 'August' seatsmax = 840 seatsocc = 690 )
    ( month = 'September' seatsmax = 840 seatsocc = 640 ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_chart
      EXPORTING
        parent = go_container.
    go_chart->set_data( data = lcl_chart=>data_xml( ) ).
  ENDIF.
  go_chart->set_customizing( data = |<SAPChartCustomizing version="1.1"><GlobalSettings><Defaults>|
                                 && |<ChartType>{ gv_chart_type }</ChartType></Defaults></GlobalSettings>|
                                 && |<Elements><ChartElements><Title><Caption>Seats per month</Caption></Title>|
                                 && |</ChartElements></Elements></SAPChartCustomizing>| ).
  go_chart->render( ).
  gv_state = |{ lines( gt_months ) } months, chart type { gv_chart_type }|.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'LINES'.
      gv_chart_type = 'Lines'.
    WHEN 'COLUMNS'.
      gv_chart_type = 'Columns'.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
