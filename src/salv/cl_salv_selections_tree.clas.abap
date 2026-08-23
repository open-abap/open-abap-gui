CLASS cl_salv_selections_tree DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS get_selected_nodes
      RETURNING
        VALUE(value) TYPE salv_t_nodes.

    METHODS get_selected_node
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_node.

ENDCLASS.

CLASS cl_salv_selections_tree IMPLEMENTATION.

  METHOD get_selected_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_node.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
