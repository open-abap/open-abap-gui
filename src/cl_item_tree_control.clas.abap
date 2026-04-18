CLASS cl_item_tree_control DEFINITION PUBLIC INHERITING FROM cl_tree_control_base.
  PUBLIC SECTION.
    CONSTANTS eventid_header_click TYPE i VALUE 28.

    EVENTS item_context_menu_request
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(menu)      TYPE REF TO cl_ctmenu.
ENDCLASS.

CLASS cl_item_tree_control IMPLEMENTATION.

ENDCLASS.