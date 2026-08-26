CLASS cl_salv_nodes DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS add_node
      IMPORTING
        related_node   TYPE salv_de_node_key OPTIONAL
        relationship   TYPE i OPTIONAL
        data_row       TYPE any OPTIONAL
        text           TYPE clike OPTIONAL
        folder         TYPE abap_bool OPTIONAL
        expander       TYPE abap_bool OPTIONAL
        collapsed_icon TYPE any OPTIONAL
        expanded_icon  TYPE any OPTIONAL
        enabled        TYPE abap_bool OPTIONAL
        visible        TYPE abap_bool OPTIONAL
        row_style      TYPE any OPTIONAL
      RETURNING
        VALUE(node)    TYPE REF TO cl_salv_node
      RAISING
        cx_salv_msg.

    METHODS get_node
      IMPORTING
        node_key     TYPE salv_de_node_key
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_node
      RAISING
        cx_salv_msg.

    METHODS get_all_nodes
      RETURNING
        VALUE(value) TYPE salv_t_nodes.

    METHODS expand_all.

    METHODS collapse_all.

    METHODS delete_all
      RAISING
        cx_salv_error.

ENDCLASS.

CLASS cl_salv_nodes IMPLEMENTATION.

  METHOD add_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_all_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD expand_all.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_all.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_all.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
