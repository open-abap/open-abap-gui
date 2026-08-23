CLASS cl_salv_selections_tree DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS get_selected_nodes
      RETURNING
        VALUE(value) TYPE salv_t_nodes.

    METHODS set_selected_nodes
      IMPORTING
        value TYPE salv_t_nodes.

    METHODS get_selected_item
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_item.

    METHODS set_selected_item
      IMPORTING
        value TYPE REF TO cl_salv_item.

ENDCLASS.

CLASS cl_salv_selections_tree IMPLEMENTATION.

  METHOD get_selected_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_item.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_item.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
