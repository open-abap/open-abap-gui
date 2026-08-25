CLASS cl_gui_list_tree DEFINITION PUBLIC INHERITING FROM cl_item_tree_control.
  PUBLIC SECTION.
    CONSTANTS align_auto   TYPE i VALUE 3.
    CONSTANTS align_left   TYPE i VALUE 0.
    CONSTANTS align_center TYPE i VALUE 1.
    CONSTANTS align_right  TYPE i VALUE 2.

    CONSTANTS item_class_text   TYPE i VALUE 1.
    CONSTANTS item_class_button TYPE i VALUE 2.
    CONSTANTS item_class_link   TYPE i VALUE 3.

    CONSTANTS item_font_default TYPE i VALUE 0.
    CONSTANTS item_font_fixed   TYPE i VALUE 1.
    CONSTANTS item_font_prop    TYPE i VALUE 2.

    CONSTANTS node_sel_mode_single TYPE i VALUE 1.

    CONSTANTS eventid_node_double_click TYPE i VALUE 25.

    METHODS constructor
      IMPORTING
        parent              TYPE REF TO cl_gui_container
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        item_selection      TYPE abap_bool OPTIONAL
        with_headers        TYPE abap_bool OPTIONAL
        list_header         TYPE any OPTIONAL
        shellstyle          TYPE any OPTIONAL
        lifetime            TYPE any OPTIONAL
        name                TYPE any OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        failed
        illegal_node_selection_mode.

    METHODS add_nodes_and_items
      IMPORTING
        node_table                TYPE STANDARD TABLE OPTIONAL
        item_table                TYPE STANDARD TABLE
        item_table_structure_name TYPE clike
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_tables
        dp_error
        table_structure_name_not_found.

    METHODS delete_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS expand_node
      IMPORTING
        node_key       TYPE clike
        level_count    TYPE i OPTIONAL
        expand_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error
        node_not_found
        cannot_expand_leaf.

    METHODS get_top_node
      EXPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS item_set_text
      IMPORTING
        node_key  TYPE clike
        item_name TYPE clike
        text      TYPE clike
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error.

    METHODS node_set_n_image
      IMPORTING
        node_key TYPE clike
        n_image  TYPE tv_image
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.
ENDCLASS.

CLASS cl_gui_list_tree IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_nodes_and_items.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_all_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD expand_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_top_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD item_set_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD node_set_n_image.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
