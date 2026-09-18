CLASS cl_salv_tree DEFINITION PUBLIC INHERITING FROM cl_salv_model_base.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        hide_header TYPE abap_bool OPTIONAL
        r_container TYPE REF TO cl_gui_container OPTIONAL.

    CLASS-METHODS factory
      IMPORTING
        hide_header TYPE abap_bool OPTIONAL
        r_container TYPE REF TO cl_gui_container OPTIONAL
      EXPORTING
        r_salv_tree TYPE REF TO cl_salv_tree
      CHANGING
        t_table     TYPE STANDARD TABLE
      RAISING
        cx_salv_error.

    METHODS get_nodes
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_nodes.

    METHODS get_columns
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_columns_tree.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_functions_tree.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_selections_tree.

    METHODS get_event
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_events_tree.

    METHODS get_tree_settings
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_tree_settings.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_aggregations.

    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_layout.

    METHODS set_data
      CHANGING
        t_table TYPE STANDARD TABLE.

    METHODS display.

    METHODS trigger_link_click
      IMPORTING
        node_key   TYPE salv_de_node_key
        columnname TYPE lvc_fname.

    METHODS trigger_double_click
      IMPORTING
        node_key   TYPE salv_de_node_key
        columnname TYPE lvc_fname.

  PRIVATE SECTION.
    DATA mr_table TYPE REF TO data.
    DATA mo_nodes TYPE REF TO cl_salv_nodes.
    DATA mo_columns TYPE REF TO cl_salv_columns_tree.
    DATA mo_functions TYPE REF TO cl_salv_functions_tree.
    DATA mo_selections TYPE REF TO cl_salv_selections_tree.
    DATA mo_events TYPE REF TO cl_salv_events_tree.
    DATA mo_tree_settings TYPE REF TO cl_salv_tree_settings.
    DATA mo_aggregations TYPE REF TO cl_salv_aggregations.
    DATA mo_layout TYPE REF TO cl_salv_layout.

    METHODS build_metadata.
    METHODS get_html
      RETURNING
        VALUE(value) TYPE string.

    METHODS node_cell_value
      IMPORTING
        node         TYPE REF TO cl_salv_node
        columnname   TYPE lvc_fname
      RETURNING
        VALUE(value) TYPE string.

    METHODS node_is_visible
      IMPORTING
        node         TYPE REF TO cl_salv_node
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS render_item
      IMPORTING
        node         TYPE REF TO cl_salv_node
        columnname   TYPE lvc_fname
      RETURNING
        VALUE(value) TYPE string.

ENDCLASS.

CLASS cl_salv_tree IMPLEMENTATION.

  METHOD constructor.
    mo_nodes = NEW cl_salv_nodes( ).
    mo_columns = NEW cl_salv_columns_tree( ).
    mo_functions = NEW cl_salv_functions_tree( ).
    mo_selections = NEW cl_salv_selections_tree( ).
    mo_events = NEW cl_salv_events_tree( ).
    mo_tree_settings = NEW cl_salv_tree_settings( ).
    mo_aggregations = NEW cl_salv_aggregations( ).
    mo_layout = NEW cl_salv_layout( ).
    mo_tree_settings->set_hierarchy_header( 'Hierarchy' ).
    IF hide_header = abap_true.
      mo_tree_settings->set_header( `` ).
    ENDIF.
  ENDMETHOD.

  METHOD factory.
    r_salv_tree = NEW cl_salv_tree(
      hide_header = hide_header
      r_container = r_container ).
    r_salv_tree->set_data( CHANGING t_table = t_table ).
  ENDMETHOD.

  METHOD get_aggregations.
    value = mo_aggregations.
  ENDMETHOD.

  METHOD get_layout.
    value = mo_layout.
  ENDMETHOD.

  METHOD set_data.
    GET REFERENCE OF t_table INTO mr_table.
    build_metadata( ).
  ENDMETHOD.

  METHOD get_nodes.
    value = mo_nodes.
  ENDMETHOD.

  METHOD get_columns.
    value = mo_columns.
  ENDMETHOD.

  METHOD get_functions.
    value = mo_functions.
  ENDMETHOD.

  METHOD get_selections.
    value = mo_selections.
  ENDMETHOD.

  METHOD get_event.
    value = mo_events.
  ENDMETHOD.

  METHOD get_tree_settings.
    value = mo_tree_settings.
  ENDMETHOD.

  METHOD display.
    cl_gui_control=>set_external_html( get_html( ) ).
  ENDMETHOD.

  METHOD trigger_link_click.
    mo_events->raise_link_click( columnname = columnname
                                 node_key   = node_key ).
  ENDMETHOD.

  METHOD trigger_double_click.
    mo_events->raise_double_click( columnname = columnname
                                   node_key   = node_key ).
  ENDMETHOD.

  METHOD build_metadata.
    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_line_descr TYPE REF TO cl_abap_datadescr.
    IF mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( mr_table->* ).
    lo_line_descr = lo_table_descr->get_table_line_type( ).
    IF lo_line_descr->kind = cl_abap_typedescr=>kind_struct.
      DATA(lo_struct_descr) = CAST cl_abap_structdescr( lo_line_descr ).
      LOOP AT lo_struct_descr->get_components( ) INTO DATA(ls_component).
        mo_columns->add_column( CONV lvc_fname( ls_component-name ) ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD get_html.
    DATA lv_header TYPE string.
    lv_header = mo_tree_settings->get_header( ).
    IF lv_header IS INITIAL.
      lv_header = 'SALV tree'.
    ENDIF.
    value = |<section class="gg-salv-tree" aria-label="SALV tree"><h2>{ cl_gui_control=>escape_html( lv_header ) }</h2><div class="gg-salv-tree-scroll"><table><thead><tr><th scope="col">{ cl_gui_control=>escape_html( CONV string( mo_tree_settings->get_hierarchy_header( ) ) ) }</th>|.
    LOOP AT mo_columns->get( ) INTO DATA(ls_column_ref).
      DATA(lo_column) = ls_column_ref-r_column.
      value = value && |<th scope="col" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_column_ref-columnname ) ) }">{ cl_gui_control=>escape_html( COND string( WHEN lo_column->get_long_text( ) IS NOT INITIAL THEN lo_column->get_long_text( ) ELSE ls_column_ref-columnname ) ) }</th>|.
    ENDLOOP.
    value = value && '</tr></thead><tbody>'.
    DATA(lt_selected) = mo_selections->get_selected_nodes( ).
    DATA(lt_nodes) = mo_nodes->get_all_nodes( ).
    LOOP AT lt_nodes INTO DATA(ls_node_ref).
      DATA(lo_node) = ls_node_ref-node.
      DATA(lv_level) = 1.
      DATA(lv_parent_key) = ``.
      TRY.
          DATA(lo_parent) = lo_node->get_parent( ).
          IF lo_parent IS BOUND.
            lv_parent_key = CONV string( lo_parent->get_key( ) ).
          ENDIF.
          DO 32 TIMES.
            IF lo_parent IS NOT BOUND.
              EXIT.
            ENDIF.
            lv_level = lv_level + 1.
            lo_parent = lo_parent->get_parent( ).
          ENDDO.
        CATCH cx_salv_msg.
          CLEAR lo_parent.
      ENDTRY.
      DATA(lv_has_children) = xsdbool( lines( lo_node->mt_children ) > 0 OR lo_node->mv_expander = abap_true ).
      DATA(lv_expanded) = xsdbool( lo_node->is_expanded( ) = abap_true AND lv_has_children = abap_true ).
      DATA(lv_selected) = xsdbool( line_exists( lt_selected[ node_key = ls_node_ref-node_key ] ) ).
      DATA(lv_selected_attr) = COND string(
        WHEN lv_selected = abap_true THEN ' aria-selected="true"'
        ELSE ' aria-selected="false"' ).
      DATA(lv_expanded_attr) = COND string(
        WHEN lv_has_children = abap_true THEN | aria-expanded="{ COND string( WHEN lv_expanded = abap_true THEN 'true' ELSE 'false' ) }"|
        ELSE `` ).
      IF node_is_visible( lo_node ) = abap_true.
        DATA(lv_indent) = ( lv_level - 1 ) * 18.
        DATA(lv_tree_marker) = COND string(
          WHEN lv_has_children = abap_false THEN ``
          WHEN lv_expanded = abap_true THEN '&#9662;'
          ELSE '&#9656;' ).
        DATA(lv_icon_name) = COND string(
          WHEN lo_node->is_folder( ) = abap_true OR lv_has_children = abap_true
            THEN COND string( WHEN lv_expanded = abap_true THEN 'folder-open' ELSE 'folder' )
          ELSE 'file-code' ).
        DATA(lv_node_icon) = zcl_gg_host_icons=>icon( iv_name = lv_icon_name ).
        DATA(lv_icon_code) = COND string(
          WHEN lv_expanded = abap_true AND lo_node->mv_expanded_icon IS NOT INITIAL
            THEN lo_node->mv_expanded_icon
          ELSE lo_node->mv_collapsed_icon ).
        DATA(lv_icon_code_attr) = COND string(
          WHEN lv_icon_code IS INITIAL THEN ``
          ELSE | data-sap-image="{ cl_gui_control=>escape_html( lv_icon_code ) }"| ).
        value = value && |<tr role="treeitem" tabindex="0" aria-level="{ lv_level }" data-tree-level="{ lv_level }" data-has-children="{ COND string( WHEN lv_has_children = abap_true THEN 'true' ELSE 'false' ) }" data-node-key="{ cl_gui_control=>escape_html( CONV string( lo_node->get_key( ) ) ) }" data-parent-key="{ cl_gui_control=>escape_html( lv_parent_key ) }"{ lv_selected_attr }{ lv_expanded_attr }><th scope="row"><span class="gg-tree-indent" style="display:flex;align-items:center;gap:3px;padding-left:{ lv_indent }px"><span class="gg-tree-disclosure" aria-hidden="true" style="display:inline-block;width:12px;text-align:center">{ lv_tree_marker }</span><span class="gg-tree-node-icon" aria-hidden="true"{ lv_icon_code_attr }>{ lv_node_icon }</span><span class="gg-tree-node-label">{ cl_gui_control=>escape_html( CONV string( lo_node->get_text( ) ) ) }</span></span></th>|.
        LOOP AT mo_columns->get( ) INTO ls_column_ref.
          DATA(lv_item_html) = render_item(
            node       = lo_node
            columnname = ls_column_ref-columnname ).
          value = value && |<td data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_column_ref-columnname ) ) }">{ lv_item_html }</td>|.
        ENDLOOP.
        value = value && '</tr>'.
      ENDIF.
    ENDLOOP.
    value = value && '</tbody></table></div></section>'.
  ENDMETHOD.

  METHOD node_cell_value.
    DATA lr_row TYPE REF TO data.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.

    IF columnname = '&Hierarchy'.
      value = CONV string( node->get_text( ) ).
      RETURN.
    ENDIF.
    lr_row = node->get_data_row( ).
    IF lr_row IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_row->* TO <row>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT columnname OF STRUCTURE <row> TO <component>.
    IF sy-subrc = 0.
      value = |{ <component> }|.
    ENDIF.
  ENDMETHOD.

  METHOD node_is_visible.
    value = node->is_visible( ).
    IF value = abap_false.
      RETURN.
    ENDIF.
    TRY.
        DATA(lo_parent) = node->get_parent( ).
        WHILE lo_parent IS BOUND.
          IF lo_parent->is_folder( ) = abap_true
              AND lo_parent->is_expanded( ) = abap_false.
            value = abap_false.
            RETURN.
          ENDIF.
          lo_parent = lo_parent->get_parent( ).
        ENDWHILE.
      CATCH cx_salv_msg.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD render_item.
    DATA lo_item TYPE REF TO cl_salv_item.
    TRY.
        lo_item = node->get_item( columnname ).
      CATCH cx_salv_msg.
        RETURN.
    ENDTRY.
    DATA(lv_text) = lo_item->get_value( ).
    IF lv_text IS INITIAL.
      lv_text = node_cell_value( node       = node
                                 columnname = columnname ).
    ENDIF.
    DATA(lv_type) = lo_item->get_type( ).
    DATA(lv_key) = cl_gui_control=>escape_html( CONV string( node->get_key( ) ) ).
    DATA(lv_column) = cl_gui_control=>escape_html( CONV string( columnname ) ).
    DATA(lv_text_escaped) = cl_gui_control=>escape_html( lv_text ).
    DATA(lv_accessible_text) = COND string(
      WHEN lv_text IS INITIAL THEN |{ columnname } for { node->get_key( ) }|
      ELSE lv_text ).
    DATA(lv_accessible_escaped) = cl_gui_control=>escape_html( lv_accessible_text ).
    DATA(lv_state) = COND string( WHEN lo_item->is_editable( ) = abap_true THEN '' ELSE ' aria-readonly="true"' ).
    DATA(lv_checked) = COND string( WHEN lo_item->is_checked( ) = abap_true THEN ' checked' ELSE '' ).
    CASE lv_type.
      WHEN if_salv_c_cell_type=>checkbox OR if_salv_c_cell_type=>checkbox_hotspot.
        value = |<label class="gg-salv-cell gg-salv-cell--checkbox"><input type="checkbox" aria-label="{ lv_accessible_escaped }" data-salv-event="checkbox-change" data-node-key="{ lv_key }" data-columnname="{ lv_column }"{ lv_checked }{ lv_state }><span class="gg-visually-hidden">{ lv_accessible_escaped }</span></label>|.
      WHEN if_salv_c_cell_type=>button.
        value = |<button type="button" class="gg-salv-cell gg-salv-cell--button" data-salv-event="button" data-node-key="{ lv_key }" data-columnname="{ lv_column }">{ lv_text_escaped }</button>|.
      WHEN if_salv_c_cell_type=>dropdown.
        value = |<select class="gg-salv-cell gg-salv-cell--dropdown" data-salv-event="dropdown" data-node-key="{ lv_key }" data-columnname="{ lv_column }"><option selected>{ lv_text_escaped }</option></select>|.
      WHEN if_salv_c_cell_type=>link OR if_salv_c_cell_type=>hotspot.
        value = |<a href="#" class="gg-salv-cell gg-salv-cell--link" data-salv-event="link-click" data-node-key="{ lv_key }" data-columnname="{ lv_column }"{ lv_state }>{ lv_text_escaped }</a>|.
      WHEN OTHERS.
        value = |<span class="gg-salv-cell" data-salv-event="text" data-node-key="{ lv_key }" data-columnname="{ lv_column }"{ lv_state }>{ lv_text_escaped }</span>|.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
