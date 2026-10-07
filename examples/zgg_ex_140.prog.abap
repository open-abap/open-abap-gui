REPORT zgg_ex_140.

TYPES ty_nodes TYPE STANDARD TABLE OF mtreesnode WITH DEFAULT KEY.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_expand_no_children FOR EVENT expand_no_children OF cl_gui_simple_tree
      IMPORTING node_key.
    CLASS-METHODS on_node_double_click FOR EVENT node_double_click OF cl_gui_simple_tree
      IMPORTING node_key.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_tree TYPE REF TO cl_gui_simple_tree.
DATA gt_nodes TYPE ty_nodes.
DATA gt_events TYPE cntl_simple_events.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.
DATA gv_node_key TYPE tv_nodekey.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_expand_no_children.
    DATA lt_children TYPE ty_nodes.

    CASE node_key.
      WHEN 'LH'.
        lt_children = VALUE #(
          ( node_key = 'LH0400' relatkey = 'LH' relatship = cl_gui_simple_tree=>relat_last_child
            text = 'LH 0400 Frankfurt - New York' )
          ( node_key = 'LH0402' relatkey = 'LH' relatship = cl_gui_simple_tree=>relat_last_child
            text = 'LH 0402 Frankfurt - New York' ) ).
      WHEN 'UA'.
        lt_children = VALUE #(
          ( node_key = 'UA0941' relatkey = 'UA' relatship = cl_gui_simple_tree=>relat_last_child
            text = 'UA 0941 Frankfurt - San Francisco' ) ).
    ENDCASE.
    go_tree->add_nodes( table_structure_name = 'MTREESNODE'
                        node_table           = lt_children ).
    gv_state = |{ lines( lt_children ) } flight(s) of { node_key } loaded|.
  ENDMETHOD.

  METHOD on_node_double_click.
    gv_state = |Double click on node { node_key }|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_tree = NEW #( parent              = go_container
                     node_selection_mode = cl_gui_simple_tree=>node_sel_mode_single ).
    gt_events = VALUE #(
      ( eventid = cl_gui_simple_tree=>eventid_expand_no_children appl_event = abap_true )
      ( eventid = cl_gui_simple_tree=>eventid_node_double_click appl_event = abap_true ) ).
    go_tree->set_registered_events( gt_events ).
    SET HANDLER lcl_handler=>on_expand_no_children FOR go_tree.
    SET HANDLER lcl_handler=>on_node_double_click FOR go_tree.
    gt_nodes = VALUE #(
      ( node_key = 'ROOT' isfolder = abap_true text = 'Airlines' )
      ( node_key = 'LH' relatkey = 'ROOT' relatship = cl_gui_simple_tree=>relat_last_child
        isfolder = abap_true expander = abap_true text = 'Lufthansa' )
      ( node_key = 'UA' relatkey = 'ROOT' relatship = cl_gui_simple_tree=>relat_last_child
        isfolder = abap_true expander = abap_true text = 'United Airlines' ) ).
    go_tree->add_nodes( table_structure_name = 'MTREESNODE'
                        node_table           = gt_nodes ).
    go_tree->expand_node( 'ROOT' ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SELECTED'.
    go_tree->get_selected_node( IMPORTING node_key = gv_node_key ).
    IF gv_node_key IS INITIAL.
      gv_state = 'No node selected'.
    ELSE.
      gv_state = |Selected node { gv_node_key }|.
    ENDIF.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
