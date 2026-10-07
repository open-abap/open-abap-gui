REPORT zgg_ex_141.

TYPES ty_nodes TYPE treev_ntab.
TYPES ty_items TYPE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY.

CLASS lcl_trees DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS build_nodes.
    CLASS-METHODS create_list_tree.
    CLASS-METHODS create_column_tree.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_splitter TYPE REF TO cl_gui_easy_splitter_container.
DATA go_list_tree TYPE REF TO cl_gui_list_tree.
DATA go_column_tree TYPE REF TO cl_gui_column_tree.
DATA gs_header TYPE treev_hhdr.
DATA gt_nodes TYPE ty_nodes.
DATA gt_items TYPE ty_items.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_splitter = NEW #( parent      = go_container
                         orientation = cl_gui_easy_splitter_container=>orientation_horizontal ).
    lcl_trees=>build_nodes( ).
    lcl_trees=>create_list_tree( ).
    lcl_trees=>create_column_tree( ).
    gv_state = |{ lines( gt_nodes ) } nodes in both trees|.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CLEAR gv_ok_code.
ENDMODULE.

CLASS lcl_trees IMPLEMENTATION.
  METHOD build_nodes.
    gt_nodes = VALUE #(
      ( node_key = 'ROOT' isfolder = abap_true expander = abap_true )
      ( node_key = 'LH0400' relatkey = 'ROOT' relatship = cl_gui_column_tree=>relat_last_child )
      ( node_key = 'UA0941' relatkey = 'ROOT' relatship = cl_gui_column_tree=>relat_last_child ) ).
    gt_items = VALUE #(
      ( node_key = 'ROOT' item_name = '1' class = cl_gui_column_tree=>item_class_text text = 'Flights' )
      ( node_key = 'LH0400' item_name = '1' class = cl_gui_column_tree=>item_class_text text = 'LH 0400' )
      ( node_key = 'LH0400' item_name = '2' class = cl_gui_column_tree=>item_class_text text = 'On time' )
      ( node_key = 'UA0941' item_name = '1' class = cl_gui_column_tree=>item_class_text text = 'UA 0941' )
      ( node_key = 'UA0941' item_name = '2' class = cl_gui_column_tree=>item_class_text text = 'Delayed' ) ).
  ENDMETHOD.

  METHOD create_list_tree.
    gs_header-heading = 'Flight'.
    gs_header-width = 20.
    go_list_tree = NEW #( parent              = go_splitter->top_left_container
                          node_selection_mode = cl_gui_list_tree=>node_sel_mode_single
                          item_selection      = abap_false
                          with_headers        = abap_true
                          hierarchy_header    = gs_header ).
    go_list_tree->add_nodes_and_items(
      node_table                = gt_nodes
      item_table                = gt_items
      item_table_structure_name = 'MTREEITM' ).
    go_list_tree->expand_node( 'ROOT' ).
  ENDMETHOD.

  METHOD create_column_tree.
    DATA lt_items TYPE ty_items.

    gs_header-heading = 'Flight'.
    gs_header-width = 20.
    go_column_tree = NEW #( parent                = go_splitter->bottom_right_container
                            node_selection_mode   = cl_gui_column_tree=>node_sel_mode_single
                            item_selection        = abap_false
                            hierarchy_column_name = 'FLIGHT'
                            hierarchy_header      = gs_header ).
    go_column_tree->add_column( name        = 'STATUS'
                                width       = 15
                                header_text = 'Status' ).
    LOOP AT gt_items INTO DATA(ls_item).
      ls_item-item_name = COND #( WHEN ls_item-item_name = '1' THEN 'FLIGHT' ELSE 'STATUS' ).
      APPEND ls_item TO lt_items.
    ENDLOOP.
    go_column_tree->add_nodes_and_items(
      node_table                = gt_nodes
      item_table                = lt_items
      item_table_structure_name = 'MTREEITM' ).
    go_column_tree->expand_node( 'ROOT' ).
  ENDMETHOD.
ENDCLASS.
