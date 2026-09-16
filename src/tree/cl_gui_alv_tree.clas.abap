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
    ms_hierarchy_header = is_hierarchy_header.
    cl_gui_control=>set_payload( control = me
                                 payload = |Hierarchy column: { is_hierarchy_header-heading }| ).
  ENDMETHOD.

  METHOD get_parent.
    tree_get_parent( EXPORTING i_node_key        = i_node_key
                     IMPORTING e_parent_node_key = e_parent_node_key ).
  ENDMETHOD.

  METHOD change_item.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc = 0 AND i_fieldname = c_hierarchy_column_name.
      ls_node-text = CONV string( i_data ).
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
      refresh_tree_html( ).
    ENDIF.
  ENDMETHOD.

  METHOD unselect_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      IF line_exists( it_node_key[ table_line = ls_node-node_key ] ).
        ls_node-selected = abap_false.
        MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
      ENDIF.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD get_checked_items.
    et_checked_items = mt_checked_items.
  ENDMETHOD.

  METHOD get_subtree.
    DATA lt_pending TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    APPEND CONV string( i_node_key ) TO lt_pending.
    WHILE lt_pending IS NOT INITIAL.
      READ TABLE lt_pending INTO DATA(lv_pending) INDEX 1.
      DELETE lt_pending INDEX 1.
      APPEND CONV lvc_nkey( lv_pending ) TO et_subtree_nodes.
      LOOP AT mt_html_nodes INTO DATA(ls_child)
          WHERE parent_key = lv_pending.
        APPEND ls_child-node_key TO lt_pending.
      ENDLOOP.
    ENDWHILE.
  ENDMETHOD.

  METHOD collapse_subtree.
    set_html_node_state( node_key = CONV string( i_node_key )
                         expanded = abap_false ).
  ENDMETHOD.

  METHOD get_expanded_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node) WHERE expanded = abap_true.
      APPEND CONV lvc_nkey( ls_node-node_key ) TO ct_expanded_nodes.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_top_node.
    e_node_key = CONV lvc_nkey( mv_html_top_node ).
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
    FIELD-SYMBOLS <selected_nodes> TYPE ANY TABLE.
    FIELD-SYMBOLS <selected_node> TYPE any.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      ls_node-selected = abap_false.
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    ENDLOOP.
    ASSIGN it_selected_nodes TO <selected_nodes>.
    IF sy-subrc = 0.
      LOOP AT <selected_nodes> ASSIGNING <selected_node>.
        READ TABLE mt_html_nodes INTO ls_node
          WITH KEY node_key = CONV string( <selected_node> ).
        IF sy-subrc = 0.
          ls_node-selected = abap_true.
          MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
        ENDIF.
      ENDLOOP.
    ENDIF.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD expand_nodes.
    FIELD-SYMBOLS <node_keys> TYPE ANY TABLE.
    ASSIGN it_node_key TO <node_keys>.
    IF sy-subrc = 0.
      LOOP AT <node_keys> ASSIGNING FIELD-SYMBOL(<node_key>).
        set_html_node_state( node_key = CONV string( <node_key> )
                             expanded = abap_true ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD get_selected_item.
    READ TABLE mt_html_nodes INTO DATA(ls_node) WITH KEY selected = abap_true.
    IF sy-subrc = 0.
      e_selected_node = ls_node-node_key.
    ENDIF.
  ENDMETHOD.

  METHOD get_selected_nodes.
    FIELD-SYMBOLS <selected_nodes> TYPE ANY TABLE.
    ASSIGN ct_selected_nodes TO <selected_nodes>.
    IF sy-subrc = 0.
      LOOP AT mt_html_nodes INTO DATA(ls_node) WHERE selected = abap_true.
        APPEND CONV lvc_nkey( ls_node-node_key ) TO <selected_nodes>.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD expand_node.
    set_html_node_state( node_key = CONV string( i_node_key )
                         expanded = abap_true ).
  ENDMETHOD.

  METHOD add_node.
    DATA(lv_key) = |TREE-{ lines( mt_html_nodes ) + 1 }|.
    IF is_outtab_line IS SUPPLIED.
      IF i_node_text IS NOT INITIAL.
        add_html_node( node_key   = lv_key
                       parent_key = CONV string( i_relat_node_key )
                       text       = CONV string( i_node_text )
                       data_row   = is_outtab_line ).
      ELSE.
        add_html_node( node_key   = lv_key
                       parent_key = CONV string( i_relat_node_key )
                       text       = lv_key
                       data_row   = is_outtab_line ).
      ENDIF.
    ELSEIF i_node_text IS NOT INITIAL.
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
    DATA lt_subtree TYPE lvc_t_nkey.
    get_subtree(
      EXPORTING
        i_node_key       = i_node_key
      IMPORTING
        et_subtree_nodes = lt_subtree ).
    LOOP AT lt_subtree INTO DATA(lv_node_key).
      DELETE mt_html_nodes WHERE node_key = CONV string( lv_node_key ).
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD delete_all_nodes.
    clear_html_nodes( ).
  ENDMETHOD.

  METHOD set_table_for_first_display.
    GET REFERENCE OF it_outtab INTO mt_outtab.
    IF it_fieldcatalog IS SUPPLIED.
      mt_fieldcatalog = it_fieldcatalog.
    ENDIF.
    cl_gui_control=>set_payload( control = me
                                 payload = |Tree rows: { lines( it_outtab ) }| ).
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD get_outtab_line.
    FIELD-SYMBOLS <outtab> TYPE ANY TABLE.
    FIELD-SYMBOLS <outtab_line> TYPE any.
    ASSIGN mt_outtab->* TO <outtab>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.
    DATA(lv_index) = 0.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc = 0.
      e_node_text = ls_node-text.
      IF ls_node-data_row IS BOUND.
        ASSIGN ls_node-data_row->* TO <outtab_line>.
        IF sy-subrc = 0.
          e_outtab_line = <outtab_line>.
          RETURN.
        ENDIF.
      ENDIF.
      DATA(lv_key) = CONV string( i_node_key ).
      REPLACE FIRST OCCURRENCE OF 'TREE-' IN lv_key WITH ``.
      lv_index = CONV i( lv_key ).
    ENDIF.
    READ TABLE <outtab> ASSIGNING <outtab_line> INDEX lv_index.
    IF sy-subrc = 0.
      e_outtab_line = <outtab_line>.
    ELSE.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
