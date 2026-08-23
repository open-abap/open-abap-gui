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
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
