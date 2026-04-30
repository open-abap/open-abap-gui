CLASS cl_item_tree_control DEFINITION PUBLIC INHERITING FROM cl_tree_control_base.
  PUBLIC SECTION.
    CONSTANTS item_class_checkbox TYPE i VALUE 3.

    CONSTANTS eventid_button_click TYPE i VALUE 29.
    CONSTANTS eventid_checkbox_change TYPE i VALUE 33.
    CONSTANTS eventid_header_click TYPE i VALUE 28.
    CONSTANTS eventid_header_context_men_req TYPE i VALUE 41.
    CONSTANTS eventid_item_context_menu_req TYPE i VALUE 26.
    CONSTANTS eventid_item_double_click TYPE i VALUE 22.
    CONSTANTS eventid_item_keypress TYPE i VALUE 39.
    CONSTANTS eventid_link_click TYPE i VALUE 35.

    EVENTS item_context_menu_request
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(menu)      TYPE REF TO cl_ctmenu.

    EVENTS item_double_click
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname.

    METHODS update_nodes_and_items
      IMPORTING
        node_table                TYPE any OPTIONAL
        item_table                TYPE STANDARD TABLE OPTIONAL
        item_table_structure_name TYPE any
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_tables
        dp_error
        table_structure_name_not_found.

    METHODS delete_all_items_of_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error.

    METHODS delete_items
      IMPORTING
        item_key_table TYPE any
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_item_key_table
        dp_error.

    METHODS item_set_t_image
      IMPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
        t_image   TYPE tv_image
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error.

    METHODS item_set_chosen
      IMPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
        chosen    TYPE abap_bool
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error
        chosen_not_supported.

    METHODS item_set_editable
      IMPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
        editable  TYPE abap_bool
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error
        no_item_selection
        editable_not_supported.

    METHODS get_selected_item
      EXPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
      EXCEPTIONS
        failed
        cntl_system_error
        no_item_selection.

    EVENTS checkbox_change
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(checked)   TYPE abap_bool.
ENDCLASS.

CLASS cl_item_tree_control IMPLEMENTATION.
  METHOD update_nodes_and_items.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_all_items_of_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_items.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_item.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD item_set_editable.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD item_set_chosen.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD item_set_t_image.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.