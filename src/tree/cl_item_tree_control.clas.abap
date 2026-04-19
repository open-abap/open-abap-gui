CLASS cl_item_tree_control DEFINITION PUBLIC INHERITING FROM cl_tree_control_base.
  PUBLIC SECTION.
    CONSTANTS eventid_header_click TYPE i VALUE 28.
    CONSTANTS item_class_checkbox TYPE i VALUE 3.

    EVENTS item_context_menu_request
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(menu)      TYPE REF TO cl_ctmenu.

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
ENDCLASS.

CLASS cl_item_tree_control IMPLEMENTATION.
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