CLASS ltcl_tree_model DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS keeps_tree_state FOR TESTING.
ENDCLASS.

CLASS ltcl_tree_model IMPLEMENTATION.
  METHOD keeps_tree_state.
    DATA lt_nodes TYPE treemlnota.
    DATA lt_items TYPE treemlitac.
    DATA lt_expanded TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_parent TYPE tm_nodekey.
    DATA ls_item TYPE treemlitem.
    DATA lv_summary TYPE string.

    APPEND VALUE #( node_key  = 'ROOT'
                    relatship = cl_list_tree_model=>relat_first_child
                    isfolder  = abap_true
                    expander  = abap_true ) TO lt_nodes.
    APPEND VALUE #( node_key  = 'CHILD'
                    relatkey  = 'ROOT'
                    relatship = cl_list_tree_model=>relat_last_child ) TO lt_nodes.
    APPEND VALUE #( node_key  = 'CHILD'
                    item_name = 'TEXT'
                    text      = 'Child text'
                    class     = cl_list_tree_model=>item_class_text
                    chosen    = abap_true ) TO lt_items.

    DATA(lo_model) = NEW cl_list_tree_model( with_headers = abap_false ).
    lo_model->add_nodes( lt_nodes ).
    lo_model->add_items( lt_items ).
    lo_model->node_get_parent(
      EXPORTING
        node_key        = 'CHILD'
      IMPORTING
        parent_node_key = lv_parent ).
    lo_model->node_get_item(
      EXPORTING
        node_key  = 'CHILD'
        item_name = 'TEXT'
      IMPORTING
        item      = ls_item ).
    lo_model->expand_node(
      node_key       = 'CHILD'
      expand_parents = abap_true ).
    lo_model->get_expanded_nodes( IMPORTING node_key_table = lt_expanded ).
    lv_summary = lo_model->get_state_summary( ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_parent
      exp = 'ROOT' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_item-text
      exp = 'Child text' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_expanded )
      exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_summary CS 'model=LIST' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_summary CS 'nodes=2' ) ).
    lo_model->collapse_node( 'ROOT' ).
    lo_model->delete_node( 'ROOT' ).
    CLEAR lt_expanded.
    lo_model->get_expanded_nodes( IMPORTING node_key_table = lt_expanded ).
    cl_abap_unit_assert=>assert_initial( lt_expanded ).
  ENDMETHOD.
ENDCLASS.
