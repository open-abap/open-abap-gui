REPORT zgg_ex_143.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         seatsocc TYPE i,
       END OF ty_flight.

CLASS lcl_tree DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS add_nodes.
ENDCLASS.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_outtab TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gs_header TYPE treev_hhdr.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_tree TYPE REF TO cl_gui_alv_tree.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' seatsocc = 180 )
    ( carrid = 'LH' connid = '0402' seatsocc = 240 )
    ( carrid = 'UA' connid = '0941' seatsocc = 210 ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_tree
      EXPORTING
        parent              = go_container
        node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
        item_selection      = abap_false
        no_html_header      = abap_true.
    gt_fieldcat = VALUE #(
      ( fieldname = 'CARRID' coltext = 'Airline' outputlen = 7 )
      ( fieldname = 'CONNID' coltext = 'Flight' outputlen = 6 )
      ( fieldname = 'SEATSOCC' coltext = 'Occupied' outputlen = 8 do_sum = abap_true ) ).
    gs_header-heading = 'Airline / flight'.
    gs_header-width = 30.
    go_tree->set_table_for_first_display(
      EXPORTING
        is_hierarchy_header = gs_header
      CHANGING
        it_outtab           = gt_outtab
        it_fieldcatalog     = gt_fieldcat ).
    lcl_tree=>add_nodes( ).
    go_tree->frontend_update( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CLEAR gv_ok_code.
ENDMODULE.

CLASS lcl_tree IMPLEMENTATION.
  METHOD add_nodes.
    DATA lv_carrier_key TYPE lvc_nkey.
    DATA lv_flight_key TYPE lvc_nkey.
    DATA lv_carrid TYPE c LENGTH 3.
    DATA lv_text TYPE lvc_value.

    LOOP AT gt_flights INTO DATA(ls_flight).
      IF ls_flight-carrid <> lv_carrid.
        lv_carrid = ls_flight-carrid.
        lv_text = lv_carrid.
        go_tree->add_node(
          EXPORTING
            i_relat_node_key = space
            i_relationship   = cl_gui_column_tree=>relat_last_child
            i_node_text      = lv_text
          IMPORTING
            e_new_node_key   = lv_carrier_key ).
      ENDIF.
      go_tree->add_node(
        EXPORTING
          i_relat_node_key = lv_carrier_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = |{ ls_flight-carrid } { ls_flight-connid }|
          is_outtab_line   = ls_flight
        IMPORTING
          e_new_node_key   = lv_flight_key ).
    ENDLOOP.
    gv_state = |{ lines( gt_flights ) } flights below their airlines|.
  ENDMETHOD.
ENDCLASS.
