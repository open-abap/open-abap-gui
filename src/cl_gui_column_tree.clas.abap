CLASS cl_gui_column_tree DEFINITION PUBLIC.
  PUBLIC SECTION.
    CONSTANTS align_center         TYPE i VALUE 1.
    CONSTANTS eventid_button_click TYPE i VALUE 1.
    CONSTANTS eventid_link_click   TYPE i VALUE 2.
    CONSTANTS item_class_button    TYPE i VALUE 2.
    CONSTANTS item_class_link      TYPE i VALUE 3.
    CONSTANTS item_class_text      TYPE i VALUE 1.
    CONSTANTS node_sel_mode_single TYPE i VALUE 1.
    CONSTANTS relat_last_child     TYPE i VALUE 1.
    CONSTANTS style_inactive       TYPE i VALUE 3.
    CONSTANTS style_emphasized     TYPE i VALUE 7.

    METHODS free.

    METHODS add_nodes_and_items
      IMPORTING
        node_table                TYPE any OPTIONAL
        item_table                TYPE STANDARD TABLE
        item_table_structure_name TYPE clike
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_tables
        dp_error
        table_structure_name_not_found.

    METHODS set_registered_events
      IMPORTING
        events TYPE cntl_simple_events
      EXCEPTIONS
        cntl_error
        cntl_system_error
        illegal_event_combination.

    METHODS delete_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS add_column
      IMPORTING
        name           TYPE clike
        hidden         TYPE abap_bool OPTIONAL
        disabled       TYPE abap_bool OPTIONAL
        alignment      TYPE i OPTIONAL
        width          TYPE i
        width_pix      TYPE abap_bool OPTIONAL
        header_image   TYPE clike OPTIONAL
        header_text    TYPE clike
        header_tooltip TYPE clike OPTIONAL
      EXCEPTIONS
        column_exists
        illegal_column_name
        too_many_columns
        illegal_alignment
        different_column_types
        cntl_system_error
        failed
        predecessor_column_not_found.

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

    EVENTS button_click
      EXPORTING
        VALUE(node_key) TYPE string
        VALUE(item_name) TYPE string.
    EVENTS link_click
      EXPORTING
        VALUE(node_key) TYPE string
        VALUE(item_name) TYPE string.
ENDCLASS.

CLASS cl_gui_column_tree IMPLEMENTATION.

  METHOD expand_node.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD free.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_column.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_nodes_and_items.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_registered_events.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD delete_all_nodes.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.