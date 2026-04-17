CLASS cl_tree_control_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS eventid_expand_no_children TYPE i VALUE 1.
    CONSTANTS eventid_node_context_menu_req TYPE i VALUE 2.

    METHODS collapse_subtree
      IMPORTING
        node_key TYPE tv_nodekey.

    METHODS expand_nodes
      IMPORTING
        node_key_table TYPE treev_nks.

ENDCLASS.

CLASS cl_tree_control_base IMPLEMENTATION.
  METHOD expand_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_subtree.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.