CLASS cl_gui_alv_tree DEFINITION INHERITING FROM cl_alv_tree_base PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        parent              TYPE REF TO cl_gui_container OPTIONAL
        node_selection_mode TYPE i DEFAULT cl_gui_column_tree=>node_sel_mode_single
        item_selection      TYPE abap_bool DEFAULT 'X'
        no_toolbar          TYPE abap_bool OPTIONAL
        no_html_header      TYPE abap_bool OPTIONAL.

    METHODS collapse_subtree
      IMPORTING
        i_node_key TYPE lvc_nkey.

    METHODS get_parent
      IMPORTING
        i_node_key        TYPE lvc_nkey
      EXPORTING
        e_parent_node_key TYPE lvc_nkey.

    METHODS set_hierarchy_header
      IMPORTING
        is_hierarchy_header TYPE treev_hhdr
        u_t_image           TYPE abap_bool DEFAULT abap_true
        u_heading           TYPE abap_bool DEFAULT abap_true
        u_tooltip           TYPE abap_bool DEFAULT abap_true
        u_width             TYPE abap_bool DEFAULT abap_true.

    EVENTS checkbox_change
      EXPORTING
        VALUE(checked)   TYPE c
        VALUE(fieldname) TYPE lvc_fname
        VALUE(node_key)  TYPE lvc_nkey.

    EVENTS node_context_menu_request
      EXPORTING
        VALUE(node_key) TYPE lvc_nkey
        VALUE(menu)     TYPE REF TO cl_ctmenu.

    EVENTS node_context_menu_selected
      EXPORTING
        VALUE(fcode)    TYPE sy-ucomm
        VALUE(node_key) TYPE lvc_nkey.

    EVENTS on_drag_multiple
      EXPORTING
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject
        VALUE(fieldname)        TYPE lvc_fname
        VALUE(node_key_table)   TYPE lvc_t_nkey.

    EVENTS on_drag
      EXPORTING
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject
        VALUE(fieldname)        TYPE lvc_fname
        VALUE(node_key)         TYPE lvc_nkey.

    EVENTS on_drop
      EXPORTING
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject
        VALUE(node_key)         TYPE lvc_nkey.

    METHODS get_outtab_line
      IMPORTING
        i_node_key     TYPE any
      EXPORTING
        e_outtab_line  TYPE any
        e_node_text    TYPE any
        et_item_layout TYPE any
        es_node_layout TYPE any
      EXCEPTIONS
        node_not_found.

    METHODS get_expanded_nodes
      CHANGING
        ct_expanded_nodes TYPE lvc_t_nkey.

    METHODS get_top_node
      EXPORTING
        e_node_key TYPE lvc_nkey.

    EVENTS link_click
      EXPORTING
        VALUE(fieldname) TYPE string
        VALUE(node_key)  TYPE string.

    EVENTS item_double_click
      EXPORTING
        VALUE(fieldname) TYPE any
        VALUE(node_key)  TYPE any.

    EVENTS node_double_click
      EXPORTING
        VALUE(node_key) TYPE any.

    EVENTS expand_nc
      EXPORTING
        VALUE(node_key) TYPE lvc_nkey.

    EVENTS header_click
      EXPORTING
        VALUE(fieldname) TYPE lvc_fname.

    METHODS set_table_for_first_display
      IMPORTING
        i_structure_name     TYPE any OPTIONAL
        is_variant           TYPE disvariant OPTIONAL
        i_save               TYPE abap_bool OPTIONAL
        i_default            TYPE abap_bool DEFAULT 'X'
        is_hierarchy_header  TYPE any OPTIONAL
        is_exception_field   TYPE any OPTIONAL
        it_special_groups    TYPE any OPTIONAL
        it_list_commentary   TYPE any OPTIONAL
        i_logo               TYPE any OPTIONAL
        i_background_id      TYPE any OPTIONAL
        it_toolbar_excluding TYPE any OPTIONAL
        it_except_qinfo      TYPE any OPTIONAL
      CHANGING
        it_outtab            TYPE STANDARD TABLE
        it_filter            TYPE any OPTIONAL
        it_fieldcatalog      TYPE any OPTIONAL.

    METHODS delete_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS delete_subtree
      IMPORTING
        i_node_key TYPE lvc_nkey
      EXCEPTIONS
        failed
        cntl_system_error
        node_not_found
        error_in_node_key_table.

    METHODS add_node
      IMPORTING
        i_relat_node_key TYPE any
        i_relationship   TYPE i
        is_outtab_line   TYPE any OPTIONAL
        is_node_layout   TYPE lvc_s_layn OPTIONAL
        it_item_layout   TYPE lvc_t_layi OPTIONAL
        i_node_text      TYPE any OPTIONAL
      EXPORTING
        e_new_node_key   TYPE any
      EXCEPTIONS
        relat_node_not_found
        node_not_found.

    METHODS expand_node
      IMPORTING
        i_node_key       TYPE any
        i_level_count    TYPE i DEFAULT 1
        i_expand_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error
        node_not_found
        cannot_expand_leaf.

    METHODS expand_nodes
      IMPORTING
        it_node_key TYPE any.

    METHODS get_selected_item
      EXPORTING
        e_fieldname     TYPE any
        e_selected_node TYPE any.

    METHODS get_selected_nodes
      CHANGING
        ct_selected_nodes TYPE any.

    METHODS set_selected_nodes
      IMPORTING
        it_selected_nodes TYPE any.

    METHODS change_node
      IMPORTING
        i_node_key     TYPE any
        is_node_layout TYPE any OPTIONAL
        i_outtab_line  TYPE any
        it_item_layout TYPE lvc_t_laci OPTIONAL.

    METHODS get_checked_items
      EXPORTING
        et_checked_items TYPE lvc_t_chit.

    METHODS get_children
      IMPORTING
        i_node_key  TYPE lvc_nkey
      EXPORTING
        et_children TYPE lvc_t_nkey.

    METHODS set_top_node
      IMPORTING
        i_node_key TYPE lvc_nkey.

    METHODS get_subtree
      IMPORTING
        i_node_key       TYPE lvc_nkey
      EXPORTING
        et_subtree_nodes TYPE lvc_t_nkey.

    METHODS unselect_nodes
      IMPORTING
        it_node_key TYPE lvc_t_nkey.

    METHODS change_item
      IMPORTING
        i_node_key     TYPE lvc_nkey
        i_fieldname    TYPE lvc_fname
        i_data         TYPE any
        i_u_data       TYPE abap_bool DEFAULT abap_true
        is_item_layout TYPE lvc_s_laci OPTIONAL
      EXCEPTIONS
        node_not_found.
ENDCLASS.

CLASS cl_gui_alv_tree IMPLEMENTATION.
  METHOD set_hierarchy_header.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_parent.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD change_item.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD unselect_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_checked_items.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_subtree.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_subtree.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_expanded_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_top_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'ALV_TREE' ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

  METHOD set_top_node.
    mv_html_top_node = CONV string( i_node_key ).
  ENDMETHOD.

  METHOD get_children.
    LOOP AT mt_html_nodes INTO DATA(ls_node)
        WHERE parent_key = CONV string( i_node_key ).
      APPEND CONV lvc_nkey( ls_node-node_key ) TO et_children.
    ENDLOOP.
  ENDMETHOD.

  METHOD change_node.
    RETURN.
  ENDMETHOD.

  METHOD set_selected_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      set_html_node_state( node_key = ls_node-node_key
                           selected = abap_false ).
    ENDLOOP.
  ENDMETHOD.

  METHOD expand_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      set_html_node_state( node_key = ls_node-node_key
                           expanded = abap_true ).
    ENDLOOP.
  ENDMETHOD.

  METHOD get_selected_item.
    READ TABLE mt_html_nodes INTO DATA(ls_node) WITH KEY selected = abap_true.
    IF sy-subrc = 0.
      e_selected_node = ls_node-node_key.
    ENDIF.
  ENDMETHOD.

  METHOD get_selected_nodes.
    RETURN.
  ENDMETHOD.

  METHOD expand_node.
    set_html_node_state( node_key = CONV string( i_node_key )
                         expanded = abap_true ).
  ENDMETHOD.

  METHOD add_node.
    DATA(lv_key) = |TREE-{ lines( mt_html_nodes ) + 1 }|.
    IF i_node_text IS NOT INITIAL.
      add_html_node( node_key   = lv_key
                     parent_key = CONV string( i_relat_node_key )
                     text       = CONV string( i_node_text ) ).
    ELSE.
      add_html_node( node_key   = lv_key
                     parent_key = CONV string( i_relat_node_key )
                     text       = lv_key ).
    ENDIF.
    e_new_node_key = lv_key.
  ENDMETHOD.

  METHOD delete_subtree.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_all_nodes.
    clear_html_nodes( ).
  ENDMETHOD.

  METHOD set_table_for_first_display.
    cl_gui_control=>set_payload( control = me
                                 payload = |Tree rows: { lines( it_outtab ) }| ).
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD get_outtab_line.
    RETURN.
  ENDMETHOD.

ENDCLASS.
