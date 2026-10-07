REPORT zgg_ex_153.

TYPES: BEGIN OF ty_booking,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_booking.

CLASS lcl_flight DEFINITION.
  PUBLIC SECTION.
    DATA node_key TYPE tv_nodekey.
ENDCLASS.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_drag FOR EVENT on_drag OF cl_gui_simple_tree
      IMPORTING node_key drag_drop_object.
    CLASS-METHODS on_drop FOR EVENT ondrop OF cl_gui_alv_grid
      IMPORTING e_dragdropobj.
ENDCLASS.

DATA go_splitter TYPE REF TO cl_gui_easy_splitter_container.
DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_tree TYPE REF TO cl_gui_simple_tree.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_dd_tree TYPE REF TO cl_dragdrop.
DATA go_dd_grid TYPE REF TO cl_dragdrop.
DATA gv_tree_handle TYPE i.
DATA gv_grid_handle TYPE i.
DATA gt_nodes TYPE STANDARD TABLE OF mtreesnode WITH DEFAULT KEY.
DATA gt_flights TYPE STANDARD TABLE OF ty_booking WITH DEFAULT KEY.
DATA gt_bookings TYPE STANDARD TABLE OF ty_booking WITH DEFAULT KEY.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gs_layout TYPE lvc_s_layo.
DATA gv_ok_code TYPE sy-ucomm.

CLASS lcl_flight IMPLEMENTATION.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_drag.
    DATA lo_flight TYPE REF TO lcl_flight.

    lo_flight = NEW #( ).
    lo_flight->node_key = node_key.
    drag_drop_object->object = lo_flight.
  ENDMETHOD.

  METHOD on_drop.
    DATA lo_flight TYPE REF TO lcl_flight.
    DATA ls_flight TYPE ty_booking.

    lo_flight ?= e_dragdropobj->object.
    LOOP AT gt_flights INTO ls_flight.
      IF |{ ls_flight-carrid }{ ls_flight-connid }| = lo_flight->node_key.
        APPEND ls_flight TO gt_bookings.
      ENDIF.
    ENDLOOP.
    go_grid->refresh_table_display( ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'LH' connid = '0402' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' ) ).
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_splitter = NEW #( parent = go_container ).

    go_dd_tree = NEW #( ).
    go_dd_tree->add( flavor     = 'FLIGHT'
                     dragsrc    = abap_true
                     droptarget = abap_false
                     effect     = cl_dragdrop=>copy ).
    go_dd_tree->get_handle( IMPORTING handle = gv_tree_handle ).
    go_dd_grid = NEW #( ).
    go_dd_grid->add( flavor     = 'FLIGHT'
                     dragsrc    = abap_false
                     droptarget = abap_true
                     effect     = cl_dragdrop=>copy ).
    go_dd_grid->get_handle( IMPORTING handle = gv_grid_handle ).

    go_tree = NEW #( parent              = go_splitter->top_left_container
                     node_selection_mode = cl_gui_simple_tree=>node_sel_mode_single ).
    gt_nodes = VALUE #(
      ( node_key = 'LH' isfolder = abap_true expander = abap_true text = 'Lufthansa' )
      ( node_key = 'LH0400' relatkey = 'LH' relatship = cl_gui_simple_tree=>relat_last_child
        text = 'LH 0400 Frankfurt - New York' dragdropid = gv_tree_handle )
      ( node_key = 'LH0402' relatkey = 'LH' relatship = cl_gui_simple_tree=>relat_last_child
        text = 'LH 0402 Frankfurt - New York' dragdropid = gv_tree_handle )
      ( node_key = 'UA' isfolder = abap_true expander = abap_true text = 'United Airlines' )
      ( node_key = 'UA0941' relatkey = 'UA' relatship = cl_gui_simple_tree=>relat_last_child
        text = 'UA 0941 Frankfurt - San Francisco' dragdropid = gv_tree_handle ) ).
    go_tree->add_nodes( table_structure_name = 'MTREESNODE'
                        node_table           = gt_nodes ).
    go_tree->expand_root_nodes( ).
    SET HANDLER lcl_handler=>on_drag FOR go_tree.

    go_grid = NEW #( i_parent = go_splitter->bottom_right_container ).
    gt_fieldcat = VALUE #(
      ( fieldname = 'CARRID' coltext = 'Airline' outputlen = 7 )
      ( fieldname = 'CONNID' coltext = 'Flight' outputlen = 6 )
      ( fieldname = 'CITYFROM' coltext = 'From' outputlen = 15 )
      ( fieldname = 'CITYTO' coltext = 'To' outputlen = 15 ) ).
    gs_layout-grid_title = 'Bookings'.
    gs_layout-s_dragdrop-grid_ddid = gv_grid_handle.
    go_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_bookings
        it_fieldcatalog = gt_fieldcat ).
    SET HANDLER lcl_handler=>on_drop FOR go_grid.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( ).
  CLEAR gv_ok_code.
ENDMODULE.
