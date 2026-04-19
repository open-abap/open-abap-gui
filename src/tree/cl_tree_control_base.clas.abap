CLASS cl_tree_control_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS eventid_expand_no_children TYPE i VALUE 1.
    CONSTANTS eventid_node_context_menu_req TYPE i VALUE 2.

    CONSTANTS style_intensified TYPE i VALUE 2.
    CONSTANTS style_intensifd_critical TYPE i VALUE 4.


    METHODS collapse_subtree
      IMPORTING
        node_key TYPE tv_nodekey.

    METHODS expand_nodes
      IMPORTING
        node_key_table TYPE treev_nks.

    METHODS expand_root_nodes
      IMPORTING
        level_count    TYPE i OPTIONAL
        expand_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error.

    METHODS collapse_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

ENDCLASS.

CLASS cl_tree_control_base IMPLEMENTATION.
  METHOD collapse_all_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD expand_root_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD expand_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_subtree.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.