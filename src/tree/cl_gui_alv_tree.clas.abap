CLASS cl_gui_alv_tree DEFINITION INHERITING FROM cl_alv_tree_base PUBLIC.
  PUBLIC SECTION.

    METHODS free.

    METHODS get_outtab_line
      IMPORTING
        i_node_key     TYPE any
      EXPORTING
        e_outtab_line  TYPE any
        e_node_text    TYPE any
        et_item_layout TYPE any
        es_node_layout TYPE any
      EXCEPTIONS
        node_not_found.

    METHODS set_registered_events
      IMPORTING
        events TYPE cntl_simple_events
      EXCEPTIONS
        cntl_error
        cntl_system_error
        illegal_event_combination.

    METHODS get_registered_events
      EXPORTING
        events TYPE cntl_simple_events
      EXCEPTIONS
        cntl_error.

    EVENTS link_click
      EXPORTING
        VALUE(fieldname) TYPE string
        VALUE(node_key)  TYPE string.

    EVENTS item_double_click
      EXPORTING
        VALUE(fieldname) TYPE any
        VALUE(node_key) TYPE any.

    EVENTS node_double_click
      EXPORTING
        VALUE(node_key) TYPE any.

    METHODS get_toolbar_object
      EXPORTING
        er_toolbar TYPE REF TO cl_gui_toolbar.

    METHODS set_table_for_first_display
      IMPORTING
        i_structure_name     TYPE any OPTIONAL
        is_variant           TYPE any OPTIONAL
        i_save               TYPE abap_bool OPTIONAL
        i_default            TYPE abap_bool DEFAULT 'X'
        is_hierarchy_header  TYPE any OPTIONAL
        is_exception_field   TYPE any OPTIONAL
        it_special_groups    TYPE any OPTIONAL
        it_list_commentary   TYPE any OPTIONAL
        i_logo               TYPE any OPTIONAL
        i_background_id      TYPE any OPTIONAL
        it_toolbar_excluding TYPE any OPTIONAL
        it_except_qinfo      TYPE any OPTIONAL
      CHANGING
        it_outtab       TYPE STANDARD TABLE
        it_filter       TYPE any OPTIONAL
        it_fieldcatalog TYPE any OPTIONAL.

    METHODS delete_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS add_node
      IMPORTING
        i_relat_node_key TYPE any
        i_relationship   TYPE i
        is_outtab_line   TYPE any OPTIONAL
        is_node_layout   TYPE any OPTIONAL
        it_item_layout   TYPE any OPTIONAL
        i_node_text      TYPE any OPTIONAL
      EXPORTING
        e_new_node_key   TYPE any
      EXCEPTIONS
        relat_node_not_found
        node_not_found.

    METHODS expand_node
      IMPORTING
        i_node_key       TYPE any
        i_level_count    TYPE i DEFAULT 1
        i_expand_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error
        node_not_found
        cannot_expand_leaf.

    METHODS frontend_update.

    METHODS expand_nodes
      IMPORTING
        it_node_key TYPE any.

    METHODS get_selected_item
      EXPORTING
        e_selected_node TYPE any.

    METHODS get_selected_nodes
      CHANGING
        ct_selected_nodes TYPE any.

    METHODS set_selected_nodes
      IMPORTING
        it_selected_nodes TYPE any.

    METHODS change_node
      IMPORTING
        i_node_key     TYPE any
        is_node_layout TYPE any
        i_outtab_line  TYPE any.

    METHODS get_children
      IMPORTING
        i_node_key TYPE lvc_nkey
      EXPORTING
        et_children TYPE lvc_t_nkey.

    METHODS set_top_node
      IMPORTING
        i_node_key TYPE lvc_nkey.
ENDCLASS.

CLASS cl_gui_alv_tree IMPLEMENTATION.

  METHOD set_top_node.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_children.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD change_node.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_selected_nodes.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD expand_nodes.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_selected_item.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD free.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_selected_nodes.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD frontend_update.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD expand_node.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_node.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD delete_all_nodes.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_table_for_first_display.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_toolbar_object.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_registered_events.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_registered_events.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_outtab_line.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.