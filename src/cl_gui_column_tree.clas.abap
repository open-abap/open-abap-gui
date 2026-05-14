CLASS cl_gui_column_tree DEFINITION PUBLIC INHERITING FROM cl_item_tree_control.
  PUBLIC SECTION.
    CONSTANTS align_center         TYPE i VALUE 1.
    CONSTANTS align_right          TYPE i VALUE 2.

    CONSTANTS eventid_node_double_click TYPE i VALUE 25.

    CONSTANTS item_class_button    TYPE i VALUE 2.
    CONSTANTS item_class_link      TYPE i VALUE 3.
    CONSTANTS item_class_text      TYPE i VALUE 1.
    CONSTANTS node_sel_mode_single TYPE i VALUE 1.

    CONSTANTS style_emphasized          TYPE i VALUE 1.
    CONSTANTS style_emphasized_positive TYPE i VALUE 4.
    CONSTANTS style_inactive            TYPE i VALUE 5.

    METHODS constructor
      IMPORTING
        parent                TYPE REF TO cl_gui_container
        node_selection_mode   TYPE i
        item_selection        TYPE abap_bool
        hierarchy_column_name TYPE clike
        hierarchy_header      TYPE treev_hhdr.

    METHODS hierarchy_header_set_text
      IMPORTING
        text TYPE any
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS hierarchy_header_set_tooltip
      IMPORTING
        tooltip TYPE any
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS hierarchy_header_set_width
      IMPORTING
        width     TYPE i
        width_pix TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        cntl_system_error.

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

    METHODS column_set_hidden
      IMPORTING
        column_name TYPE tv_itmname
        hidden      TYPE abap_bool
      EXCEPTIONS
        failed
        column_not_found
        cntl_system_error.

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

    METHODS hierarchy_header_get_width
      IMPORTING
        width_pix TYPE abap_bool DEFAULT abap_true
      EXPORTING
        width     TYPE i.

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

    METHODS column_get_width
      IMPORTING
        column_name TYPE any
        width_pix   TYPE abap_bool DEFAULT abap_true
      EXPORTING
        width       TYPE i.

    METHODS adjust_column_width
      IMPORTING
        start_column    TYPE any OPTIONAL
        end_column      TYPE any OPTIONAL
        all_columns     TYPE abap_bool OPTIONAL
        include_heading TYPE abap_bool OPTIONAL.
ENDCLASS.

CLASS cl_gui_column_tree IMPLEMENTATION.
  METHOD hierarchy_header_set_width.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hierarchy_header_set_tooltip.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hierarchy_header_set_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD column_set_hidden.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD adjust_column_width.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD column_get_width.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD hierarchy_header_get_width.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

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