CLASS ltcl_tree_model DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS keeps_tree_state FOR TESTING.
    METHODS renders_simple_model_control FOR TESTING.
    METHODS renders_item_model_controls FOR TESTING.
ENDCLASS.

CLASS cl_tree_model DEFINITION LOCAL FRIENDS ltcl_tree_model.

CLASS ltcl_tree_model IMPLEMENTATION.
  METHOD renders_simple_model_control.
    DATA lt_nodes TYPE treemsnota.
    DATA lv_html TYPE string.
    DATA(lo_host) = NEW cl_gui_custom_container( container_name = 'TREE_MODEL_SIMPLE' ).
    DATA(lo_model) = NEW cl_simple_tree_model( node_selection_mode = 1 ).

    lt_nodes = VALUE #(
      ( node_key = 'ROOT' isfolder = abap_true text = 'Simple Tree Root' expander = abap_true )
      ( node_key = 'P100' relatkey = 'ROOT' text = 'Mechanical Keyboard' ) ).
    lo_model->add_nodes( lt_nodes ).
    lo_model->create_tree_control( parent = lo_host ).
    lo_model->expand_node( node_key = 'ROOT' ).
    lv_html = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'TREE_MODEL_SIMPLE' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Simple Tree Root' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Mechanical Keyboard' ) ).
  ENDMETHOD.

  METHOD renders_item_model_controls.
    DATA lt_list_nodes TYPE treemlnota.
    DATA lt_list_items TYPE treemlitac.
    DATA lt_column_nodes TYPE treemcnota.
    DATA lt_column_items TYPE treemcitac.
    DATA lv_html TYPE string.
    DATA(lo_list_host) = NEW cl_gui_custom_container( container_name = 'TREE_MODEL_LIST' ).
    DATA(lo_list) = NEW cl_list_tree_model( with_headers = abap_true ).
    DATA(lo_column_host) = NEW cl_gui_custom_container( container_name = 'TREE_MODEL_COLUMN' ).
    DATA(lo_column) = NEW cl_column_tree_model( ).

    lt_list_nodes = VALUE #(
      ( node_key = 'ROOT' isfolder = abap_true expander = abap_true )
      ( node_key = 'P100' relatkey = 'ROOT' relatship = cl_tree_model=>relat_last_child ) ).
    lt_list_items = VALUE #(
      ( node_key = 'ROOT' item_name = 'NODE' text = 'List Tree Root' )
      ( node_key = 'P100' item_name = 'NODE' text = 'P100' )
      ( node_key = 'P100' item_name = 'NAME' text = 'Mechanical Keyboard' ) ).
    lo_list->add_nodes( lt_list_nodes ).
    lo_list->add_items( lt_list_items ).
    lo_list->create_tree_control( parent = lo_list_host ).
    lo_list->expand_node( node_key = 'ROOT' ).
    lo_list->item_set_text( node_key  = 'P100'
                            item_name = 'NAME'
                            text      = 'Updated Keyboard' ).
    lv_html = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'TREE_MODEL_LIST' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'List Tree Root' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Updated Keyboard' ) ).

    lt_column_nodes = VALUE #(
      ( node_key = 'ROOT' isfolder = abap_true expander = abap_true )
      ( node_key = 'P200' relatkey = 'ROOT' ) ).
    lt_column_items = VALUE #(
      ( node_key = 'ROOT' item_name = 'NODE' text = 'Column Tree Root' )
      ( node_key = 'P200' item_name = 'NODE' text = 'P200' )
      ( node_key = 'P200' item_name = 'PRODUCT' text = '27 Inch Display' )
      ( node_key = 'P200' item_name = 'STATE' text = 'Ready' ) ).
    lo_column->add_nodes( lt_column_nodes ).
    lo_column->add_items( lt_column_items ).
    lo_column->create_tree_control( parent = lo_column_host ).
    lo_column->expand_node( node_key = 'ROOT' ).
    lv_html = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'TREE_MODEL_COLUMN' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Column Tree Root' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '27 Inch Display' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Ready' ) ).
  ENDMETHOD.

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
