CLASS cl_simple_tree_model DEFINITION PUBLIC INHERITING FROM cl_tree_model.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL.

    METHODS add_nodes
      IMPORTING
        node_table TYPE treemsnota
      EXCEPTIONS
        error_in_node_table
        failed
        cntl_system_error.

ENDCLASS.

CLASS cl_simple_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    mv_model_kind = 'SIMPLE'.
  ENDMETHOD.

  METHOD add_nodes.
    LOOP AT node_table INTO DATA(ls_input).
      store_node( VALUE #( node_key   = CONV string( ls_input-node_key )
                           parent_key = CONV string( ls_input-relatkey )
                           text       = CONV string( ls_input-node_key )
                           expanded   = xsdbool( ls_input-expander IS NOT INITIAL )
                           hidden     = xsdbool( ls_input-hidden IS NOT INITIAL ) ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
