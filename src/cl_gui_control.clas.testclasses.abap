CLASS ltcl_control_helpers DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS salv_filter_options FOR TESTING
      RAISING
        cx_salv_data_error
        cx_salv_existing
        cx_salv_not_found.
    METHODS grid_filter_options FOR TESTING.
    METHODS column_tree_indent FOR TESTING.

    METHODS salv_keeps
      IMPORTING
        option        TYPE salv_de_selopt_option
        low           TYPE salv_de_selopt_low
        high          TYPE salv_de_selopt_high OPTIONAL
        sign          TYPE salv_de_selopt_sign DEFAULT 'I'
      RETURNING
        VALUE(result) TYPE string
      RAISING
        cx_salv_data_error
        cx_salv_existing
        cx_salv_not_found.

    METHODS grid_keeps
      IMPORTING
        option        TYPE char2
        low           TYPE lvc_value
        high          TYPE lvc_value OPTIONAL
        sign          TYPE char1 DEFAULT 'I'
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS ltcl_control_helpers IMPLEMENTATION.

  METHOD salv_keeps.
    TYPES: BEGIN OF ty_row,
             carrier TYPE c LENGTH 3,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    lt_rows = VALUE #( ( carrier = 'AA' ) ( carrier = 'LH' ) ( carrier = 'UA' ) ).
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_filters( )->add_filter(
      columnname = 'CARRIER'
      sign       = sign
      option     = option
      low        = low
      high       = high ).
    DATA(lv_html) = lo_salv->get_html( ).
    LOOP AT lt_rows INTO DATA(ls_row).
      IF lv_html CS |>{ ls_row-carrier }<|.
        result = result && CONV string( ls_row-carrier ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD grid_keeps.
    TYPES: BEGIN OF ty_row,
             carrier TYPE c LENGTH 3,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_filter TYPE lvc_t_filt.
    DATA lo_grid TYPE REF TO cl_gui_alv_grid.

    lt_rows = VALUE #( ( carrier = 'AA' ) ( carrier = 'LH' ) ( carrier = 'UA' ) ).
    APPEND VALUE #( fieldname = 'CARRIER' inttype = 'C' ) TO lt_fcat.
    APPEND VALUE #( fieldname = 'CARRIER'
                    sign      = sign
                    option    = option
                    low       = low
                    high      = high ) TO lt_filter.
    lo_grid = NEW cl_gui_alv_grid( i_parent = NEW cl_gui_custom_container(
      container_name = 'TMP' ) ).
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat
        it_filter       = lt_filter ).
    DATA(lv_html) = cl_gui_control=>render_html( iv_document = abap_false ).
    LOOP AT lt_rows INTO DATA(ls_row).
      IF lv_html CS |>{ ls_row-carrier }<|.
        result = result && CONV string( ls_row-carrier ).
      ENDIF.
    ENDLOOP.
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD salv_filter_options.
* Rows are AA, LH, UA. COMPARE_OPTION backs both filter sources, so each
* option is pinned here for the SALV reading and below for the grid reading.
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'EQ' low = 'LH' )
                                        exp = 'LH'
                                        msg = 'salv EQ' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'NE' low = 'LH' )
                                        exp = 'AAUA'
                                        msg = 'salv NE' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'BT' low = 'AA' high = 'LH' )
                                        exp = 'AALH'
                                        msg = 'salv BT' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'NB' low = 'AA' high = 'LH' )
                                        exp = 'UA'
                                        msg = 'salv NB' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'GE' low = 'LH' )
                                        exp = 'LHUA'
                                        msg = 'salv GE' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'GT' low = 'LH' )
                                        exp = 'UA'
                                        msg = 'salv GT' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'LE' low = 'LH' )
                                        exp = 'AALH'
                                        msg = 'salv LE' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'LT' low = 'LH' )
                                        exp = 'AA'
                                        msg = 'salv LT' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'CP' low = '*A' )
                                        exp = 'AAUA'
                                        msg = 'salv CP' ).
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'NP' low = '*A' )
                                        exp = 'LH'
                                        msg = 'salv NP' ).
* An excluding sign inverts the outcome.
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'EQ' low = 'LH' sign = 'E' )
                                        exp = 'AAUA'
                                        msg = 'salv EQ excluding' ).
* An unrecognised option drops every row in SALV.
    cl_abap_unit_assert=>assert_equals( act = salv_keeps( option = 'ZZ' low = 'LH' )
                                        exp = ''
                                        msg = 'salv unknown option' ).
  ENDMETHOD.

  METHOD grid_filter_options.
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'EQ' low = 'LH' )
                                        exp = 'LH'
                                        msg = 'grid EQ' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'NE' low = 'LH' )
                                        exp = 'AAUA'
                                        msg = 'grid NE' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'BT' low = 'AA' high = 'LH' )
                                        exp = 'AALH'
                                        msg = 'grid BT' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'NB' low = 'AA' high = 'LH' )
                                        exp = 'UA'
                                        msg = 'grid NB' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'GE' low = 'LH' )
                                        exp = 'LHUA'
                                        msg = 'grid GE' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'GT' low = 'LH' )
                                        exp = 'UA'
                                        msg = 'grid GT' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'LE' low = 'LH' )
                                        exp = 'AALH'
                                        msg = 'grid LE' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'LT' low = 'LH' )
                                        exp = 'AA'
                                        msg = 'grid LT' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'CP' low = '*A' )
                                        exp = 'AAUA'
                                        msg = 'grid CP' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'NP' low = '*A' )
                                        exp = 'LH'
                                        msg = 'grid NP' ).
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'EQ' low = 'LH' sign = 'E' )
                                        exp = 'AAUA'
                                        msg = 'grid EQ excluding' ).
* An unrecognised option compares for equality in the ALV grid, which is where
* the two filter sources disagree.
    cl_abap_unit_assert=>assert_equals( act = grid_keeps( option = 'ZZ' low = 'LH' )
                                        exp = 'LH'
                                        msg = 'grid unknown option' ).
  ENDMETHOD.

  METHOD column_tree_indent.
    DATA lt_nodes TYPE treemcnota.
    DATA lt_items TYPE treemcitac.
    DATA lo_tree TYPE REF TO cl_gui_column_tree.

    lo_tree = NEW cl_gui_column_tree(
      parent                = NEW cl_gui_custom_container( container_name = 'TMPTREE' )
      node_selection_mode   = cl_gui_column_tree=>node_sel_mode_single
      item_selection        = abap_true
      hierarchy_column_name = 'HIER'
      hierarchy_header      = VALUE treev_hhdr( heading = 'Hierarchy' width = 30 ) ).
    lo_tree->add_column(
      name        = 'VALUE'
      width       = 24
      header_text = 'Description' ).

    lt_nodes = VALUE #( ( node_key = 'R' )
                        ( node_key = 'C' relatkey = 'R' )
                        ( node_key = 'G' relatkey = 'C' ) ).
    lt_items = VALUE #( ( node_key = 'R' item_name = 'NODE'
                          class = cl_gui_column_tree=>item_class_text text = 'root' )
                        ( node_key = 'C' item_name = 'NODE'
                          class = cl_gui_column_tree=>item_class_text text = 'child' )
                        ( node_key = 'G' item_name = 'NODE'
                          class = cl_gui_column_tree=>item_class_text text = 'grand' ) ).
    lo_tree->add_nodes_and_items(
      node_table                = lt_nodes
      item_table                = lt_items
      item_table_structure_name = 'MTREEITEM' ).

    DATA(lv_html) = cl_gui_control=>render_html( iv_document = abap_false ).
* Root at level 1 gets no indent, its child 18px, the grandchild 36px.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-tree-level="1" data-has-children="true" data-node-key="R"' )
                                      msg = 'root level' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'padding-left:0px' )
                                      msg = 'root indent' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'padding-left:18px' )
                                      msg = 'child indent' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'padding-left:36px' )
                                      msg = 'grandchild indent' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-tree-node-label">root</span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-tree-node-label">child</span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-tree-node-label">grand</span>' ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_html CS 'style="width:30ch"' )
      msg = 'hierarchy width uses SAP character units' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_html CS 'style="width:24ch"' )
      msg = 'item column width uses SAP character units' ).
    lo_tree->hierarchy_header_set_width(
      width     = 210
      width_pix = abap_true ).
    lv_html = cl_gui_control=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_html CS 'style="width:210px"' )
      msg = 'pixel widths stay in pixels' ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

ENDCLASS.
