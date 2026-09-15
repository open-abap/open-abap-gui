CLASS cl_salv_node DEFINITION PUBLIC FRIENDS cl_salv_nodes cl_salv_tree.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        node_key TYPE salv_de_node_key
        text     TYPE clike OPTIONAL
        data_row TYPE any OPTIONAL.

    METHODS get_key
      RETURNING
        VALUE(value) TYPE salv_de_node_key.

    METHODS get_item
      IMPORTING
        columnname   TYPE lvc_fname
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_item
      RAISING
        cx_salv_msg.

    METHODS get_hierarchy_item
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_item.

    METHODS set_text
      IMPORTING
        value TYPE clike.

    METHODS get_text
      RETURNING
        VALUE(value) TYPE lvc_value.

    METHODS set_data_row
      IMPORTING
        value TYPE any.

    METHODS get_parent
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_node
      RAISING
        cx_salv_msg.

    METHODS get_children
      RETURNING
        VALUE(value) TYPE salv_t_nodes
      RAISING
        cx_salv_msg.

    METHODS get_data_row
      RETURNING
        VALUE(value) TYPE REF TO data.

    METHODS set_row_style
      IMPORTING
        value TYPE i.

    METHODS set_collapsed_icon
      IMPORTING
        value TYPE any.

    METHODS set_expanded_icon
      IMPORTING
        value TYPE any.

    METHODS set_folder
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_expander
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS expand
      IMPORTING
        subtree TYPE abap_bool OPTIONAL.

    METHODS collapse.

    METHODS is_folder
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS is_visible
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_visible
      IMPORTING
        value TYPE abap_bool.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_item_state,
             columnname TYPE lvc_fname,
             item       TYPE REF TO cl_salv_item,
           END OF ty_item_state.
    TYPES ty_item_states TYPE STANDARD TABLE OF ty_item_state WITH DEFAULT KEY.
    DATA mv_key TYPE salv_de_node_key.
    DATA mv_text TYPE lvc_value.
    DATA mr_data_row TYPE REF TO data.
    DATA mr_parent TYPE REF TO cl_salv_node.
    DATA mt_children TYPE salv_t_nodes.
    DATA mt_items TYPE ty_item_states.
    DATA mv_row_style TYPE i.
    DATA mv_collapsed_icon TYPE string.
    DATA mv_expanded_icon TYPE string.
    DATA mv_folder TYPE abap_bool.
    DATA mv_expander TYPE abap_bool.
    DATA mv_expanded TYPE abap_bool.
    DATA mv_visible TYPE abap_bool.

    METHODS set_parent
      IMPORTING
        value TYPE REF TO cl_salv_node.

    METHODS add_child
      IMPORTING
        value TYPE REF TO cl_salv_node.

    METHODS is_expanded
      RETURNING
        VALUE(value) TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_node IMPLEMENTATION.

  METHOD constructor.
    mv_key = node_key.
    mv_text = text.
    mv_folder = abap_false.
    mv_expander = abap_false.
    mv_expanded = abap_true.
    mv_visible = abap_true.
    IF data_row IS SUPPLIED.
      GET REFERENCE OF data_row INTO mr_data_row.
    ENDIF.
  ENDMETHOD.

  METHOD get_key.
    value = mv_key.
  ENDMETHOD.

  METHOD get_item.
    READ TABLE mt_items INTO DATA(ls_item) WITH KEY columnname = columnname.
    IF sy-subrc = 0.
      value = ls_item-item.
      RETURN.
    ENDIF.
    DATA(lo_item) = NEW cl_salv_item( ).
    APPEND VALUE #( columnname = columnname item = lo_item ) TO mt_items.
    value = lo_item.
  ENDMETHOD.

  METHOD get_hierarchy_item.
    TRY.
        value = get_item( columnname = '&Hierarchy' ).
      CATCH cx_salv_msg.
        RETURN.
    ENDTRY.
    value->set_value( mv_text ).
  ENDMETHOD.

  METHOD set_text.
    mv_text = value.
  ENDMETHOD.

  METHOD get_text.
    value = mv_text.
  ENDMETHOD.

  METHOD set_data_row.
    GET REFERENCE OF value INTO mr_data_row.
  ENDMETHOD.

  METHOD get_parent.
    value = mr_parent.
  ENDMETHOD.

  METHOD get_children.
    value = mt_children.
  ENDMETHOD.

  METHOD get_data_row.
    value = mr_data_row.
  ENDMETHOD.

  METHOD set_row_style.
    mv_row_style = value.
  ENDMETHOD.

  METHOD set_collapsed_icon.
    mv_collapsed_icon = value.
  ENDMETHOD.

  METHOD set_expanded_icon.
    mv_expanded_icon = value.
  ENDMETHOD.

  METHOD set_folder.
    mv_folder = value.
  ENDMETHOD.

  METHOD set_expander.
    mv_expander = value.
  ENDMETHOD.

  METHOD expand.
    mv_expanded = abap_true.
    IF subtree = abap_true.
      LOOP AT mt_children INTO DATA(lo_child).
        lo_child-node->expand( subtree = abap_true ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD collapse.
    mv_expanded = abap_false.
  ENDMETHOD.

  METHOD set_parent.
    mr_parent = value.
  ENDMETHOD.

  METHOD add_child.
    APPEND VALUE #( node_key = value->get_key( )
                    node     = value ) TO mt_children.
  ENDMETHOD.

  METHOD is_expanded.
    value = mv_expanded.
  ENDMETHOD.

  METHOD is_folder.
    value = mv_folder.
  ENDMETHOD.

  METHOD is_visible.
    value = mv_visible.
  ENDMETHOD.

  METHOD set_visible.
    mv_visible = value.
  ENDMETHOD.

ENDCLASS.
