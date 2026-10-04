REPORT zgg_ex_148.

TYPES: BEGIN OF ty_carrier,
         carrname TYPE c LENGTH 20,
         seatsocc TYPE i,
       END OF ty_carrier.

CLASS lcl_chart DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS data_xml
      RETURNING
        VALUE(rv_xml) TYPE string.
ENDCLASS.

DATA gt_carriers TYPE STANDARD TABLE OF ty_carrier WITH DEFAULT KEY.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_chart TYPE REF TO cl_gui_chart_engine.
DATA gv_chart_type TYPE string VALUE 'Bars'.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_chart IMPLEMENTATION.
  METHOD data_xml.
    DATA lv_values TYPE string.

    rv_xml = '<?xml version="1.0" encoding="utf-8"?><SimpleChartData><Categories>'.
    LOOP AT gt_carriers INTO DATA(ls_carrier).
      rv_xml = |{ rv_xml }<C>{ ls_carrier-carrname }</C>|.
      lv_values = |{ lv_values }<S>{ ls_carrier-seatsocc }</S>|.
    ENDLOOP.
    rv_xml = |{ rv_xml }</Categories><Series label="Occupied seats">{ lv_values }</Series></SimpleChartData>|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  gt_carriers = VALUE #(
    ( carrname = 'Lufthansa' seatsocc = 420 )
    ( carrname = 'United Airlines' seatsocc = 310 )
    ( carrname = 'Air France' seatsocc = 160 ) ).
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
  PERFORM render.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'BARS'.
      gv_chart_type = 'Bars'.
    WHEN 'COLUMNS'.
      gv_chart_type = 'Columns'.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.

FORM render.
  go_chart->set_customizing( data = |<?xml version="1.0" encoding="utf-8"?><SAPChartCustomizing version="1.1">|
                                 && |<GlobalSettings><Defaults><ChartType>{ gv_chart_type }</ChartType></Defaults></GlobalSettings>|
                                 && |<Elements><ChartElements><Title><Caption>Occupied seats per airline</Caption></Title>|
                                 && |</ChartElements></Elements></SAPChartCustomizing>| ).
  go_chart->render( ).
  gv_state = |Chart type { gv_chart_type }|.
ENDFORM.
