CLASS cl_salv_selections_tree DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS set_selection_mode
      IMPORTING
        value TYPE i DEFAULT if_salv_c_selection_mode=>none.

    METHODS get_selection_mode
      RETURNING
        VALUE(value) TYPE i.

    METHODS get_selected_nodes
      RETURNING
        VALUE(value) TYPE salv_t_nodes.

    METHODS get_selected_node
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_node.

ENDCLASS.

CLASS cl_salv_selections_tree IMPLEMENTATION.

  METHOD set_selection_mode.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selection_mode.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_node.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
