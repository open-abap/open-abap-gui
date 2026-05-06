CLASS cl_tree_control_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS eventid_expand_no_children TYPE i VALUE 1.
    CONSTANTS eventid_node_context_menu_req TYPE i VALUE 2.
    CONSTANTS eventid_selection_changed TYPE i VALUE 21.
    CONSTANTS eventid_node_keypress TYPE i VALUE 40.
    CONSTANTS eventid_def_context_menu_req TYPE i VALUE 42.

    CONSTANTS style_intensified TYPE i VALUE 2.
    CONSTANTS style_intensifd_critical TYPE i VALUE 4.
    CONSTANTS style_default TYPE i VALUE 1.
    CONSTANTS style_emphasized_negative TYPE i VALUE 5.

    CONSTANTS node_sel_mode_multiple TYPE i VALUE 1.

    CONSTANTS relat_first_child TYPE i VALUE 4.
    CONSTANTS relat_last_child TYPE i VALUE 6.

    CONSTANTS style_emphasized_a TYPE i VALUE 8.
    CONSTANTS style_emphasized_b TYPE i VALUE 9.
    CONSTANTS style_emphasized_c TYPE i VALUE 10.

    CONSTANTS key_f1 TYPE i VALUE 1.

    METHODS select_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error
        multiple_node_selection_only.

    METHODS unselect_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error
        multiple_node_selection_only.

    METHODS set_ctx_menu_select_event_appl
      IMPORTING
        appl_event TYPE abap_bool.

    EVENTS on_drop
      EXPORTING
      VALUE(node_key)         TYPE tv_nodekey
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS selection_changed
      EXPORTING
      VALUE(node_key) TYPE tv_nodekey.

    EVENTS node_context_menu_select
      EXPORTING
      VALUE(node_key) TYPE tv_nodekey
      VALUE(fcode)    TYPE sy-ucomm.

    EVENTS node_keypress
      EXPORTING
      VALUE(node_key) TYPE tv_nodekey
      VALUE(key)      TYPE i.

    METHODS set_top_node
      IMPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    EVENTS on_drop_get_flavor
      EXPORTING
      VALUE(node_key)         TYPE tv_nodekey
      VALUE(flavors)          TYPE char40
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS expand_no_children
      EXPORTING
        VALUE(node_key) TYPE tv_nodekey.

    METHODS set_selected_node
      IMPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        single_node_selection_only
        node_not_found
        cntl_system_error.

    METHODS get_selected_nodes
      CHANGING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        cntl_system_error
        dp_error
        failed
        multiple_node_selection_only.

    METHODS ensure_visible
      IMPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    EVENTS node_context_menu_request
      EXPORTING
        VALUE(node_key) TYPE tv_nodekey
        VALUE(menu)     TYPE REF TO cl_ctmenu.

    EVENTS node_double_click
      EXPORTING
        VALUE(node_key) TYPE tv_nodekey.

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

    METHODS get_selected_node
      EXPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        single_node_selection_only
        cntl_system_error.

    METHODS get_expanded_nodes
      IMPORTING
        no_hidden_nodes TYPE abap_bool OPTIONAL
      CHANGING
        node_key_table  TYPE treev_nks
      EXCEPTIONS
        cntl_system_error
        dp_error
        failed.

    METHODS delete_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error.

    METHODS collapse_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error.
ENDCLASS.

CLASS cl_tree_control_base IMPLEMENTATION.
  METHOD set_default_drop.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD set_ctx_menu_select_event_appl.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD unselect_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_top_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD select_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD ensure_visible.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_expanded_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_node.
    RETURN. " todo, implement method
  ENDMETHOD.

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