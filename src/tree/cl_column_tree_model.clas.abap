CLASS cl_column_tree_model DEFINITION PUBLIC INHERITING FROM cl_item_tree_model.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        node_selection_mode   TYPE i OPTIONAL
        hide_selection        TYPE abap_bool OPTIONAL
        item_selection        TYPE abap_bool OPTIONAL
        hierarchy_column_name TYPE tv_itmname OPTIONAL
        hierarchy_header      TYPE treemhhdr OPTIONAL.

    METHODS add_column
      IMPORTING
        name           TYPE tv_itmname
        width          TYPE i OPTIONAL
        header_text    TYPE any OPTIONAL
        header_image   TYPE tv_image OPTIONAL
        header_tooltip TYPE any OPTIONAL
        alignment      TYPE i OPTIONAL
        hidden         TYPE abap_bool OPTIONAL
        disabled       TYPE abap_bool OPTIONAL
        width_pix      TYPE abap_bool OPTIONAL
      EXCEPTIONS
        column_exists
        illegal_column_name
        too_many_columns
        illegal_alignment
        different_column_types
        cntl_system_error
        failed
        predecessor_column_not_found.

    METHODS add_nodes
      IMPORTING
        node_table TYPE treemcnota
      EXCEPTIONS
        error_in_node_table
        failed
        cntl_system_error.

    METHODS add_items
      IMPORTING
        item_table TYPE treemcitac
      EXCEPTIONS
        node_not_found
        error_in_item_table
        failed
        cntl_system_error.

ENDCLASS.

CLASS cl_column_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_column.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_items.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
