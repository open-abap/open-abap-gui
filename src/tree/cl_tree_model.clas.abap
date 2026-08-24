CLASS cl_tree_model DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS node_sel_mode_single TYPE i VALUE 0.
    CONSTANTS node_sel_mode_multiple TYPE i VALUE 1.

    CONSTANTS relat_first_child TYPE i VALUE 0.
    CONSTANTS relat_last_child TYPE i VALUE 1.
    CONSTANTS relat_prev_sibling TYPE i VALUE 2.
    CONSTANTS relat_next_sibling TYPE i VALUE 3.
    CONSTANTS relat_first_sibling TYPE i VALUE 4.
    CONSTANTS relat_last_sibling TYPE i VALUE 5.

    CONSTANTS eventid_def_context_menu_req TYPE i VALUE 1.
    CONSTANTS eventid_node_context_menu_req TYPE i VALUE 2.
    CONSTANTS eventid_node_double_click TYPE i VALUE 3.
    CONSTANTS eventid_node_keypress TYPE i VALUE 4.
    CONSTANTS eventid_selection_changed TYPE i VALUE 5.

    CONSTANTS style_inherited TYPE i VALUE 0.
    CONSTANTS style_default TYPE i VALUE 1.
    CONSTANTS style_intensified TYPE i VALUE 2.
    CONSTANTS style_inactive TYPE i VALUE 3.
    CONSTANTS style_intensifd_critical TYPE i VALUE 4.
    CONSTANTS style_emphasized_negative TYPE i VALUE 5.
    CONSTANTS style_emphasized_positive TYPE i VALUE 6.
    CONSTANTS style_emphasized TYPE i VALUE 7.

    CONSTANTS scroll_up_line TYPE i VALUE 1.
    CONSTANTS scroll_down_line TYPE i VALUE 2.
    CONSTANTS scroll_up_page TYPE i VALUE 3.
    CONSTANTS scroll_down_page TYPE i VALUE 4.
    CONSTANTS scroll_home TYPE i VALUE 5.
    CONSTANTS scroll_end TYPE i VALUE 6.

    METHODS constructor
      IMPORTING
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL.

    METHODS create_tree_control
      IMPORTING
        parent     TYPE REF TO cl_gui_container OPTIONAL
        shellstyle TYPE i OPTIONAL
        lifetime   TYPE i OPTIONAL
        name       TYPE string OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        failed
        illegal_node_selection_mode.

    METHODS expand_node
      IMPORTING
        node_key       TYPE tm_nodekey
        expand_subtree TYPE abap_bool OPTIONAL
        level_count    TYPE i OPTIONAL
        expand_parents TYPE abap_bool OPTIONAL
      EXCEPTIONS
        node_not_found
        failed
        cntl_system_error.

    METHODS collapse_node
      IMPORTING
        node_key TYPE tm_nodekey
      EXCEPTIONS
        node_not_found
        failed
        cntl_system_error.

    METHODS get_expanded_nodes
      EXPORTING
        node_key_table TYPE STANDARD TABLE.

    METHODS node_get_parent
      IMPORTING
        node_key        TYPE tm_nodekey
      EXPORTING
        parent_node_key TYPE tm_nodekey
      EXCEPTIONS
        node_not_found.

    METHODS delete_all_nodes.

    METHODS delete_node
      IMPORTING
        node_key TYPE tm_nodekey
      EXCEPTIONS
        node_not_found.

    METHODS update_view.

ENDCLASS.

CLASS cl_tree_model IMPLEMENTATION.

  METHOD constructor.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_tree_control.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD expand_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_expanded_nodes.
    CLEAR node_key_table.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD node_get_parent.
    CLEAR parent_node_key.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_all_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD update_view.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
