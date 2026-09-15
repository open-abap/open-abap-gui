CLASS lcl_salv_tree_event_handler DEFINITION.
  PUBLIC SECTION.
    DATA called TYPE abap_bool.
    METHODS handle_link
      FOR EVENT link_click OF cl_salv_events_tree
      IMPORTING
        columnname
        node_key.
ENDCLASS.

CLASS lcl_salv_tree_event_handler IMPLEMENTATION.
  METHOD handle_link.
    called = xsdbool( columnname = 'NAME' AND node_key IS NOT INITIAL ).
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_salv_tree_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_hierarchy_and_state FOR TESTING
      RAISING
        cx_salv_error
        cx_salv_msg.
    METHODS renders_typed_items_and_events FOR TESTING
      RAISING
        cx_salv_error
        cx_salv_msg.
ENDCLASS.

CLASS ltcl_salv_tree_support IMPLEMENTATION.
  METHOD renders_hierarchy_and_state.
    TYPES: BEGIN OF ty_row,
             id   TYPE i,
             name TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_tree TYPE REF TO cl_salv_tree.
    DATA lo_root TYPE REF TO cl_salv_node.
    DATA lo_leaf TYPE REF TO cl_salv_node.
    DATA lt_selected TYPE salv_t_nodes.

    APPEND VALUE #( id = 1 name = 'Root' ) TO lt_rows.
    APPEND VALUE #( id = 2 name = 'Leaf <safe>' ) TO lt_rows.
    cl_gui_control=>clear( ).
    cl_salv_tree=>factory(
      EXPORTING
        hide_header = abap_false
      IMPORTING
        r_salv_tree = lo_tree
      CHANGING
        t_table     = lt_rows ).
    lo_root = lo_tree->get_nodes( )->add_node(
      text     = 'Root'
      folder   = abap_true
      expander = abap_true ).
    lo_leaf = lo_tree->get_nodes( )->add_node(
      related_node = lo_root->get_key( )
      text         = 'Leaf <safe>' ).
    APPEND VALUE #( node_key = lo_leaf->get_key( )
                    node     = lo_leaf ) TO lt_selected.
    lo_tree->get_selections( )->set_selected_nodes( lt_selected ).
    lo_tree->get_tree_settings( )->set_header( 'Tree header' ).
    lo_tree->display( ).

    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-salv-tree' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Leaf &lt;safe&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-level="2"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-selected="true"' ) ).
    lo_tree->get_nodes( )->collapse_all( ).
    cl_abap_unit_assert=>assert_false( act = lo_root->is_expanded( ) ).
  ENDMETHOD.

  METHOD renders_typed_items_and_events.
    TYPES: BEGIN OF ty_row,
             id   TYPE i,
             name TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_tree TYPE REF TO cl_salv_tree.
    DATA lo_root TYPE REF TO cl_salv_node.
    DATA lo_leaf TYPE REF TO cl_salv_node.
    DATA ls_leaf TYPE ty_row.
    DATA lo_handler TYPE REF TO lcl_salv_tree_event_handler.
    DATA lo_events TYPE REF TO cl_salv_events_tree.

    lt_rows = VALUE #( ( id = 1 name = 'Root' )
                       ( id = 2 name = 'Leaf' ) ).
    ls_leaf = lt_rows[ 2 ].
    cl_gui_control=>clear( ).
    cl_salv_tree=>factory(
      IMPORTING
        r_salv_tree = lo_tree
      CHANGING
        t_table     = lt_rows ).
    lo_root = lo_tree->get_nodes( )->add_node(
      text   = 'Root'
      folder = abap_true ).
    lo_leaf = lo_tree->get_nodes( )->add_node(
      related_node = lo_root->get_key( )
      data_row     = ls_leaf
      text         = 'Leaf' ).
    lo_leaf->get_item( 'NAME' )->set_type( if_salv_c_cell_type=>link ).
    lo_leaf->get_item( 'NAME' )->set_value( 'Open leaf' ).
    lo_root->get_item( 'ID' )->set_type( if_salv_c_cell_type=>checkbox ).
    lo_root->get_item( 'ID' )->set_checked( abap_true ).
    lo_events = lo_tree->get_event( ).
    lo_handler = NEW lcl_salv_tree_event_handler( ).
    SET HANDLER lo_handler->handle_link FOR lo_events.
    lo_tree->trigger_link_click( node_key   = lo_leaf->get_key( )
                                 columnname = 'NAME' ).
    cl_abap_unit_assert=>assert_true( act = lo_handler->called ).
    lo_tree->display( ).

    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-salv-event="link-click"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Open leaf' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'type="checkbox"' ) ).
    lo_root->collapse( ).
    lo_tree->display( ).
    lv_html = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'Open leaf' ) ).
  ENDMETHOD.
ENDCLASS.
