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

  PRIVATE SECTION.
    DATA mt_selected_nodes TYPE salv_t_nodes.
    DATA mr_selected_item TYPE REF TO cl_salv_item.

ENDCLASS.

CLASS cl_salv_selections_tree IMPLEMENTATION.

  METHOD get_selected_nodes.
    value = mt_selected_nodes.
  ENDMETHOD.

  METHOD set_selected_nodes.
    mt_selected_nodes = value.
  ENDMETHOD.

  METHOD get_selected_item.
    value = mr_selected_item.
  ENDMETHOD.

  METHOD set_selected_item.
    mr_selected_item = value.
  ENDMETHOD.

ENDCLASS.
