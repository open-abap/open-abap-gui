CLASS cl_gui_column_tree DEFINITION PUBLIC INHERITING FROM cl_item_tree_control.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        parent                TYPE REF TO cl_gui_container
        node_selection_mode   TYPE i
        item_selection        TYPE abap_bool
        hierarchy_column_name TYPE clike
        hierarchy_header      TYPE treev_hhdr.

    METHODS hierarchy_header_set_text
      IMPORTING
        text TYPE tv_heading
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS hierarchy_header_set_tooltip
      IMPORTING
        tooltip TYPE any
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS hierarchy_header_set_width
      IMPORTING
        width     TYPE i
        width_pix TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS column_set_hidden
      IMPORTING
        column_name TYPE tv_itmname
        hidden      TYPE abap_bool
      EXCEPTIONS
        failed
        column_not_found
        cntl_system_error.

    METHODS add_column
      IMPORTING
        name           TYPE clike
        hidden         TYPE abap_bool OPTIONAL
        disabled       TYPE abap_bool OPTIONAL
        alignment      TYPE i OPTIONAL
        width          TYPE i
        width_pix      TYPE abap_bool OPTIONAL
        header_image   TYPE clike OPTIONAL
        header_text    TYPE clike
        header_tooltip TYPE clike OPTIONAL
      EXCEPTIONS
        column_exists
        illegal_column_name
        too_many_columns
        illegal_alignment
        different_column_types
        cntl_system_error
        failed
        predecessor_column_not_found.

    METHODS hierarchy_header_get_width
      IMPORTING
        width_pix TYPE abap_bool DEFAULT abap_true
      EXPORTING
        width     TYPE i.

    METHODS column_get_width
      IMPORTING
        column_name TYPE any
        width_pix   TYPE abap_bool DEFAULT abap_true
      EXPORTING
        width       TYPE i.

    METHODS adjust_column_width
      IMPORTING
        start_column    TYPE any OPTIONAL
        end_column      TYPE any OPTIONAL
        all_columns     TYPE abap_bool OPTIONAL
        include_heading TYPE abap_bool OPTIONAL.

  PROTECTED SECTION.
    METHODS refresh_tree_html REDEFINITION.
    METHODS refresh_item_html REDEFINITION.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_column,
             name         TYPE string,
             hidden       TYPE abap_bool,
             disabled     TYPE abap_bool,
             alignment    TYPE i,
             width        TYPE i,
             width_pix    TYPE abap_bool,
             header_image TYPE string,
             header_text  TYPE string,
             tooltip      TYPE string,
           END OF ty_column.
    TYPES ty_columns TYPE STANDARD TABLE OF ty_column WITH DEFAULT KEY.
    DATA mt_columns TYPE ty_columns.
    DATA ms_hierarchy_header TYPE treev_hhdr.

    METHODS refresh_column_html.
ENDCLASS.

CLASS cl_gui_column_tree IMPLEMENTATION.
  METHOD hierarchy_header_set_width.
    ms_hierarchy_header-width = width.
    ms_hierarchy_header-width_pix = COND #( WHEN width_pix = abap_true THEN 'X' ELSE ' ' ).
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>) INDEX 1.
    IF sy-subrc = 0.
      <column>-width = width.
      <column>-width_pix = xsdbool( width_pix = abap_true ).
    ENDIF.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD hierarchy_header_set_tooltip.
    ms_hierarchy_header-tooltip = CONV #( tooltip ).
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>) INDEX 1.
    IF sy-subrc = 0.
      <column>-tooltip = CONV string( tooltip ).
    ENDIF.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD hierarchy_header_set_text.
    ms_hierarchy_header-heading = text.
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>) INDEX 1.
    IF sy-subrc = 0.
      <column>-header_text = CONV string( text ).
    ENDIF.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD column_set_hidden.
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>)
      WITH KEY name = CONV string( column_name ).
    IF sy-subrc = 0.
      <column>-hidden = hidden.
      refresh_column_html( ).
    ENDIF.
  ENDMETHOD.

  METHOD adjust_column_width.
    FIELD-SYMBOLS <column> TYPE ty_column.
    LOOP AT mt_columns ASSIGNING <column>.
      IF all_columns = abap_true
          OR ( start_column IS SUPPLIED AND <column>-name >= CONV string( start_column ) )
          OR ( end_column IS SUPPLIED AND <column>-name <= CONV string( end_column ) ).
        <column>-width = COND #( WHEN include_heading = abap_true
                                  AND strlen( <column>-header_text ) > 0
                                  THEN strlen( <column>-header_text ) * 8
                                 ELSE COND #( WHEN <column>-width > 0 THEN <column>-width ELSE 80 ) ).
        IF include_heading = abap_true AND strlen( <column>-header_text ) > 0.
          <column>-width_pix = abap_true.
        ELSEIF <column>-width <= 0.
          <column>-width_pix = abap_true.
        ENDIF.
      ENDIF.
    ENDLOOP.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD column_get_width.
    READ TABLE mt_columns INTO DATA(ls_column)
      WITH KEY name = CONV string( column_name ).
    IF sy-subrc = 0.
      width = ls_column-width.
    ENDIF.
  ENDMETHOD.

  METHOD hierarchy_header_get_width.
    width = ms_hierarchy_header-width.
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'COLUMN_TREE' ).
    ms_hierarchy_header = hierarchy_header.
    APPEND VALUE #( name         = CONV string( hierarchy_column_name )
                    width        = hierarchy_header-width
                    width_pix    = xsdbool( hierarchy_header-width_pix = abap_true )
                    header_image = hierarchy_header-t_image
                    header_text  = hierarchy_header-heading
                    tooltip      = hierarchy_header-tooltip ) TO mt_columns.
    refresh_column_html( ).
    parent->add_child( me ).
  ENDMETHOD.

  METHOD free.
    super->free( ).
  ENDMETHOD.

  METHOD add_column.
    READ TABLE mt_columns TRANSPORTING NO FIELDS
      WITH KEY name = CONV string( name ).
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    APPEND VALUE #( name         = CONV string( name )
                    hidden       = hidden
                    disabled     = disabled
                    alignment    = alignment
                    width        = width
                    width_pix    = width_pix
                    header_image = CONV string( header_image )
                    header_text  = CONV string( header_text )
                    tooltip      = CONV string( header_tooltip ) ) TO mt_columns.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD set_registered_events.
    super->set_registered_events( events ).
  ENDMETHOD.

  METHOD refresh_column_html.
    DATA lv_heading TYPE string.
    DATA lv_width TYPE string.
    DATA lv_html TYPE string.
    DATA lv_indent TYPE i.

    lv_heading = ms_hierarchy_header-heading.
    IF lv_heading IS INITIAL.
      lv_heading = 'Hierarchy'.
    ENDIF.
    lv_html = |<table class="gg-column-tree" aria-label="Column tree"><thead><tr>|.
    LOOP AT mt_columns INTO DATA(ls_column) WHERE hidden = abap_false.
      DATA(lv_column_heading) = ls_column-header_text.
      IF lv_column_heading IS INITIAL.
        lv_column_heading = ls_column-name.
      ENDIF.
      lv_width = COND string(
        WHEN ls_column-width > 0 AND ls_column-width_pix = abap_true
          THEN | style="width:{ ls_column-width }px"|
        WHEN ls_column-width > 0
          THEN | style="width:{ ls_column-width }ch"|
        ELSE `` ).
      lv_html = lv_html && |<th scope="col" data-column-name="{ escape_html( ls_column-name ) }"{ lv_width } title="{ escape_html( ls_column-tooltip ) }">{ escape_html( lv_column_heading ) }</th>|.
    ENDLOOP.
    lv_html = lv_html && |</tr></thead><tbody>|.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      DATA(lv_tree_level) = node_level( ls_node-node_key ).
      lv_indent = ( lv_tree_level - 1 ) * 18.
      DATA(lv_has_children) = node_has_children( ls_node-node_key ).
      DATA(lv_is_expanded) = xsdbool( lv_has_children = abap_true
                                      AND ls_node-expanded = abap_true
                                      AND line_exists( mt_html_nodes[ parent_key = ls_node-node_key ] ) ).
      DATA(lv_expanded_attr) = COND string(
        WHEN lv_has_children = abap_true
          THEN | aria-expanded="{ COND string( WHEN lv_is_expanded = abap_true THEN 'true' ELSE 'false' ) }"|
        ELSE `` ).
      DATA(lv_tree_marker) = COND string(
        WHEN lv_has_children = abap_false THEN ``
        WHEN lv_is_expanded = abap_true THEN '&#9662;'
        ELSE '&#9656;' ).
      DATA(lv_icon_name) = COND string(
        WHEN ls_node-folder = abap_true OR lv_has_children = abap_true
          THEN COND string( WHEN lv_is_expanded = abap_true THEN 'folder-open' ELSE 'folder' )
        ELSE 'file-code' ).
      DATA(lv_node_icon) = zcl_gg_host_icons=>icon( iv_name = lv_icon_name ).
      DATA(lv_node_image) = COND string(
        WHEN lv_is_expanded = abap_true AND ls_node-open_image IS NOT INITIAL THEN ls_node-open_image
        ELSE ls_node-node_image ).
      DATA(lv_visible) = xsdbool( ls_node-hidden = abap_false ).
      DATA(lv_parent_key) = ls_node-parent_key.
      DO 32 TIMES.
        IF lv_parent_key IS INITIAL.
          EXIT.
        ENDIF.
        READ TABLE mt_html_nodes INTO DATA(ls_parent)
          WITH KEY node_key = lv_parent_key.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        IF ls_parent-expanded = abap_false.
          lv_visible = abap_false.
        ENDIF.
        lv_parent_key = ls_parent-parent_key.
      ENDDO.
      DATA(lv_hidden_attr) = COND string( WHEN lv_visible = abap_false THEN ' hidden' ELSE `` ).
      DATA(lv_node_image_attr) = COND string(
        WHEN lv_node_image IS INITIAL THEN ``
        ELSE | data-sap-image="{ escape_html( lv_node_image ) }"| ).
      lv_html = lv_html && |<tr class="gg-column-tree-node" role="treeitem" tabindex="0" aria-level="{ lv_tree_level }" data-tree-level="{ lv_tree_level }" data-has-children="{ COND string( WHEN lv_has_children = abap_true THEN 'true' ELSE 'false' ) }" data-node-key="{ escape_html( ls_node-node_key ) }" data-parent-key="{ escape_html( ls_node-parent_key ) }"{ lv_expanded_attr }{ lv_hidden_attr }><th scope="row"><span class="gg-tree-indent" style="display:flex;align-items:center;gap:3px;padding-left:{ lv_indent }px"><span class="gg-tree-disclosure" aria-hidden="true" style="display:inline-block;width:12px;text-align:center">{ lv_tree_marker }</span><span class="gg-tree-node-icon" aria-hidden="true"{ lv_node_image_attr }>{ lv_node_icon }</span><span class="gg-tree-node-label">{ escape_html( ls_node-text ) }</span></span></th>|.
      LOOP AT mt_columns INTO DATA(ls_extra_column) FROM 2 WHERE hidden = abap_false.
        DATA(ls_item) = VALUE ty_html_item( ).
        READ TABLE mt_html_items INTO ls_item
          WITH KEY node_key = ls_node-node_key item_name = ls_extra_column-name.
        DATA(lv_item_text) = escape_html( ls_item-text ).
        DATA(lv_item_markup) = lv_item_text.
        CASE ls_item-item_class.
          WHEN item_class_checkbox.
            DATA(lv_checked) = COND string( WHEN ls_item-chosen = abap_true THEN ' checked' ELSE `` ).
            DATA(lv_editable) = COND string( WHEN ls_item-editable = abap_true THEN `` ELSE ' disabled' ).
            lv_item_markup = |<input type="checkbox"{ lv_checked }{ lv_editable } aria-label="{ escape_html( ls_extra_column-name ) }"> { lv_item_text }|.
          WHEN item_class_button.
            lv_item_markup = |<button type="button" class="gg-tree-item-button" data-node-key="{ escape_html( ls_node-node_key ) }" data-item-name="{ escape_html( ls_extra_column-name ) }">{ lv_item_text }</button>|.
          WHEN item_class_link.
            lv_item_markup = |<a href="#" class="gg-tree-item-link" data-node-key="{ escape_html( ls_node-node_key ) }" data-item-name="{ escape_html( ls_extra_column-name ) }">{ lv_item_text }</a>|.
          WHEN OTHERS.
            lv_item_markup = lv_item_text.
        ENDCASE.
        lv_html = lv_html && |<td data-column-name="{ escape_html( ls_extra_column-name ) }">{ lv_item_markup }</td>|.
      ENDLOOP.
      lv_html = lv_html && |</tr>|.
    ENDLOOP.
    lv_html = lv_html && |</tbody></table>|.
    cl_gui_control=>set_html(
      control = me
      html    = lv_html ).
  ENDMETHOD.

  METHOD refresh_item_html.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD refresh_tree_html.
    refresh_column_html( ).
  ENDMETHOD.

ENDCLASS.
