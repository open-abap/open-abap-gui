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

  PRIVATE SECTION.
    DATA mt_nodes TYPE salv_t_nodes.

ENDCLASS.

CLASS cl_salv_nodes IMPLEMENTATION.

  METHOD add_node.
    DATA lv_key TYPE salv_de_node_key.
    lv_key = |NODE-{ lines( mt_nodes ) + 1 }|.
    DATA(lo_node) = NEW cl_salv_node(
      node_key = lv_key
      text     = text
      data_row = data_row ).
    lo_node->set_folder( folder ).
    lo_node->set_expander( expander ).
    lo_node->set_collapsed_icon( collapsed_icon ).
    lo_node->set_expanded_icon( expanded_icon ).
    lo_node->set_row_style( row_style ).
    IF visible IS SUPPLIED.
      lo_node->set_visible( visible ).
    ENDIF.
    IF related_node IS SUPPLIED AND related_node IS NOT INITIAL.
      READ TABLE mt_nodes INTO DATA(lo_parent) WITH KEY table_line = related_node.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_salv_msg.
      ENDIF.
      lo_node->set_parent( lo_parent ).
      lo_parent->add_child( lo_node ).
    ENDIF.
    APPEND lo_node TO mt_nodes.
    node = lo_node.
  ENDMETHOD.

  METHOD get_node.
    READ TABLE mt_nodes INTO value WITH KEY table_line = node_key.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_salv_msg.
    ENDIF.
  ENDMETHOD.

  METHOD get_all_nodes.
    value = mt_nodes.
  ENDMETHOD.

  METHOD expand_all.
    LOOP AT mt_nodes INTO DATA(lo_node).
      lo_node->expand( subtree = abap_true ).
    ENDLOOP.
  ENDMETHOD.

  METHOD collapse_all.
    LOOP AT mt_nodes INTO DATA(lo_node).
      lo_node->collapse( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_all.
    CLEAR mt_nodes.
  ENDMETHOD.

ENDCLASS.
