CLASS cl_list_tree_model DEFINITION PUBLIC INHERITING FROM cl_item_tree_model.
  PUBLIC SECTION.

    CONSTANTS align_auto TYPE i VALUE 3.

    METHODS constructor
      IMPORTING
        with_headers        TYPE abap_bool
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        item_selection      TYPE abap_bool OPTIONAL
        hierarchy_header    TYPE treemhhdr OPTIONAL
        list_header         TYPE treemlhdr OPTIONAL.

    METHODS add_node
      IMPORTING
        node_key          TYPE tm_nodekey
        relative_node_key TYPE tm_nodekey OPTIONAL
        relationship      TYPE i OPTIONAL
        isfolder          TYPE abap_bool OPTIONAL
        hidden            TYPE abap_bool OPTIONAL
        disabled          TYPE abap_bool OPTIONAL
        no_branch         TYPE abap_bool OPTIONAL
        expander          TYPE abap_bool OPTIONAL
        image             TYPE tv_image OPTIONAL
        expanded_image    TYPE tv_image OPTIONAL
        style             TYPE i OPTIONAL
        drag_drop_id      TYPE i OPTIONAL
        items_incomplete  TYPE abap_bool OPTIONAL
        item_table        TYPE treemlitab OPTIONAL
        last_hitem        TYPE tv_itmname OPTIONAL
        user_object       TYPE REF TO object OPTIONAL
      EXCEPTIONS
        node_key_exists
        node_key_empty
        illegal_relationship
        relative_node_not_found
        error_in_item_table.

    METHODS add_nodes
      IMPORTING
        node_table TYPE treemlnota
      EXCEPTIONS
        error_in_node_table
        failed
        cntl_system_error.

    METHODS add_items
      IMPORTING
        item_table TYPE treemlitac
      EXCEPTIONS
        node_not_found
        error_in_item_table
        failed
        cntl_system_error.

    METHODS node_get_item
      IMPORTING
        node_key  TYPE tm_nodekey
        item_name TYPE tv_itmname
      EXPORTING
        item      TYPE treemlitem
      EXCEPTIONS
        node_not_found
        item_not_found.

ENDCLASS.

CLASS cl_list_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_items.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD node_get_item.
    CLEAR item.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
