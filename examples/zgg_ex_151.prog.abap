REPORT zgg_ex_151.

TYPES ty_html_line TYPE c LENGTH 255.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
         seatsocc TYPE i,
       END OF ty_flight.

CLASS lcl_gui DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action getdata.
    CLASS-METHODS render.
  PRIVATE SECTION.
    CLASS-METHODS add
      IMPORTING iv_html TYPE string.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_viewer TYPE REF TO cl_gui_html_viewer.
DATA gt_html TYPE STANDARD TABLE OF ty_html_line WITH DEFAULT KEY.
DATA gt_events TYPE cntl_simple_events.
DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_pages TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA gv_url TYPE c LENGTH 255.
DATA gv_ok_code TYPE sy-ucomm.

CLASS lcl_gui IMPLEMENTATION.
  METHOD on_sapevent.
    CASE action.
      WHEN 'flight'.
        APPEND getdata TO gt_pages.
      WHEN 'back'.
        IF lines( gt_pages ) > 1.
          DELETE gt_pages INDEX lines( gt_pages ).
        ENDIF.
    ENDCASE.
    render( ).
  ENDMETHOD.

  METHOD add.
    APPEND iv_html TO gt_html.
  ENDMETHOD.

  METHOD render.
    DATA lv_carrid TYPE c LENGTH 3.
    DATA lv_connid TYPE n LENGTH 4.
    DATA ls_flight TYPE ty_flight.

    CLEAR gt_html.
    add( '<html><body>' ).
    READ TABLE gt_pages INTO DATA(lv_page) INDEX lines( gt_pages ).
    IF lv_page = 'LIST'.
      add( '<h1>Flights</h1><table><tr><th>Flight</th><th>From</th><th>To</th></tr>' ).
      LOOP AT gt_flights INTO ls_flight.
        add( |<tr><td><a href="SAPEVENT:flight?{ ls_flight-carrid }-{ ls_flight-connid }">{ ls_flight-carrid } { ls_flight-connid }</a></td>| ).
        add( |<td>{ ls_flight-cityfrom }</td><td>{ ls_flight-cityto }</td></tr>| ).
      ENDLOOP.
      add( '</table>' ).
    ELSE.
      SPLIT lv_page AT '-' INTO lv_carrid lv_connid.
      READ TABLE gt_flights INTO ls_flight WITH KEY carrid = lv_carrid connid = lv_connid.
      add( |<h1>Flight { ls_flight-carrid } { ls_flight-connid }</h1>| ).
      add( |<p>{ ls_flight-cityfrom } to { ls_flight-cityto }, { ls_flight-seatsocc } seats occupied.</p>| ).
      add( '<p><a href="SAPEVENT:back">Back to the flights</a></p>' ).
    ENDIF.
    add( '</body></html>' ).
    go_viewer->load_data( IMPORTING assigned_url = gv_url
                          CHANGING  data_table   = gt_html ).
    go_viewer->show_url( url = gv_url ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' seatsocc = 180 )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' seatsocc = 210 )
    ( carrid = 'AF' connid = '0010' cityfrom = 'Paris' cityto = 'New York' seatsocc = 160 ) ).
  APPEND 'LIST' TO gt_pages.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_HTML' ).
    go_viewer = NEW #( parent = go_container ).
    gt_events = VALUE #( ( eventid    = cl_gui_html_viewer=>m_id_sapevent
                           appl_event = abap_true ) ).
    go_viewer->set_registered_events( gt_events ).
    SET HANDLER lcl_gui=>on_sapevent FOR go_viewer.
    lcl_gui=>render( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( ).
  CLEAR gv_ok_code.
ENDMODULE.
