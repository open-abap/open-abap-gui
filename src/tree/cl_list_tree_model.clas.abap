CLASS cl_list_tree_model DEFINITION PUBLIC INHERITING FROM cl_item_tree_model.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        item_selection      TYPE abap_bool OPTIONAL
        with_headers        TYPE abap_bool OPTIONAL
        hierarchy_header    TYPE treemhhdr OPTIONAL
        list_header         TYPE treemlhdr OPTIONAL.

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

ENDCLASS.

CLASS cl_list_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_items.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
