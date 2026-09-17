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

  PRIVATE SECTION.
    DATA mt_column_names TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

ENDCLASS.

CLASS cl_column_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    mv_model_kind = 'COLUMN'.
  ENDMETHOD.

  METHOD add_column.
    IF NOT line_exists( mt_column_names[ table_line = CONV string( name ) ] ).
      APPEND CONV string( name ) TO mt_column_names.
    ENDIF.
  ENDMETHOD.

  METHOD add_nodes.
    LOOP AT node_table INTO DATA(ls_node).
      store_node( VALUE #( node_key   = CONV string( ls_node-node_key )
                           parent_key = CONV string( ls_node-relatkey )
                           text       = CONV string( ls_node-text )
                           expanded   = xsdbool( ls_node-expander IS NOT INITIAL )
                           hidden     = xsdbool( ls_node-hidden IS NOT INITIAL ) ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD add_items.
    LOOP AT item_table INTO DATA(ls_item).
      DELETE mt_model_items WHERE node_key = CONV string( ls_item-node_key )
                              AND item_name = CONV string( ls_item-item_name ).
      APPEND VALUE #( node_key  = CONV string( ls_item-node_key )
                      item_name = CONV string( ls_item-item_name )
                      text      = CONV string( ls_item-text )
                      class     = ls_item-class
                      chosen    = xsdbool( ls_item-chosen IS NOT INITIAL )
                      style     = ls_item-style
                      editable  = xsdbool( ls_item-editable IS NOT INITIAL )
                      hidden    = xsdbool( ls_item-hidden IS NOT INITIAL ) ) TO mt_model_items.
    ENDLOOP.
    update_view( ).
  ENDMETHOD.

ENDCLASS.
