REPORT zgg_ex_142.

TYPES ty_nodes TYPE STANDARD TABLE OF mtreesnode WITH DEFAULT KEY.

* selection_changed is a system event: its handler runs without PAI and asks
* for PAI by setting an OK code. node_double_click is an application event: PAI
* runs and dispatches it with cl_gui_cfw=>dispatch.
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_selection_changed FOR EVENT selection_changed OF cl_gui_simple_tree
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
DATA gv_selected TYPE tv_nodekey.
DATA gv_return_code TYPE i.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_selection_changed.
    gv_selected = node_key.
    cl_gui_cfw=>set_new_ok_code( 'SELECTED' ).
  ENDMETHOD.

  METHOD on_node_double_click.
    gv_state = |Node { node_key } opened|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_tree
      EXPORTING
        parent              = go_container
        node_selection_mode = cl_gui_simple_tree=>node_sel_mode_single.
    gt_events = VALUE #(
      ( eventid = cl_gui_simple_tree=>eventid_selection_changed appl_event = abap_false )
      ( eventid = cl_gui_simple_tree=>eventid_node_double_click appl_event = abap_true ) ).
    go_tree->set_registered_events( gt_events ).
    SET HANDLER lcl_handler=>on_selection_changed FOR go_tree.
    SET HANDLER lcl_handler=>on_node_double_click FOR go_tree.
    gt_nodes = VALUE #(
      ( node_key = 'ROOT' isfolder = abap_true text = 'Flights' )
      ( node_key = 'LH0400' relatkey = 'ROOT' relatship = cl_gui_simple_tree=>relat_last_child
        text = 'LH 0400' )
      ( node_key = 'UA0941' relatkey = 'ROOT' relatship = cl_gui_simple_tree=>relat_last_child
        text = 'UA 0941' ) ).
    go_tree->add_nodes( table_structure_name = 'MTREESNODE'
                        node_table           = gt_nodes ).
    go_tree->expand_node( 'ROOT' ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( IMPORTING return_code = gv_return_code ).
  IF gv_ok_code = 'SELECTED'.
    gv_state = |Node { gv_selected } selected|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
