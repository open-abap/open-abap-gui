CLASS cl_alv_tree_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS c_hierarchy_column_name TYPE lvc_fname VALUE '&Hierarchy'.
    CONSTANTS c_virtual_root_node TYPE lvc_nkey VALUE '&VIRTUALROOT'.
    CONSTANTS c_hierarchy_header_name TYPE lvc_fname VALUE 'HierarchyHeader'.

    CONSTANTS mc_fc_current_variant TYPE ui_func VALUE '&COL0'.
    CONSTANTS mc_fc_load_variant TYPE ui_func VALUE '&LOAD'.
    CONSTANTS mc_fc_maintain_variant TYPE ui_func VALUE '&MAINTAIN'.
    CONSTANTS mc_fc_print_back TYPE ui_func VALUE '&PRINT_BACK'.
    CONSTANTS mc_fc_print_back_all TYPE ui_func VALUE '&PRINT_BACK_ALL'.
    CONSTANTS mc_fc_save_variant TYPE ui_func VALUE '&SAVE'.
    CONSTANTS mc_fc_help TYPE ui_func VALUE '&HELP'.
    CONSTANTS mc_fc_graphics TYPE ui_func VALUE '&GRAPHCIS'.

    CONSTANTS mc_fc_calculate TYPE ui_func VALUE '&CALC'.
    CONSTANTS mc_fc_calculate_avg TYPE ui_func VALUE '&CALC_AVG'.
    CONSTANTS mc_fc_calculate_max TYPE ui_func VALUE '&CALC_MAX'.
    CONSTANTS mc_fc_calculate_min TYPE ui_func VALUE '&CALC_MIN'.
    CONSTANTS mc_fc_calculate_sum TYPE ui_func VALUE '&CALC_SUM'.

    METHODS set_hierarchy_help_fields
      IMPORTING
        i_ref_table TYPE any OPTIONAL
        i_ref_field TYPE lvc_fname OPTIONAL
        i_doktitle  TYPE scrtext_s OPTIONAL
        i_rollname  TYPE any OPTIONAL.

    METHODS get_frontend_fieldcatalog
      EXPORTING
        VALUE(et_fieldcatalog) TYPE lvc_t_fcat.

    METHODS update_calculations
      IMPORTING
        no_frontend_update TYPE c OPTIONAL.

    METHODS column_optimize
      IMPORTING
        i_start_column    TYPE lvc_fname OPTIONAL
        i_end_column      TYPE lvc_fname OPTIONAL
        i_include_heading TYPE abap_bool DEFAULT abap_true.

    METHODS get_registered_events
      EXPORTING
        events TYPE cntl_simple_events
      EXCEPTIONS
        cntl_error.

    METHODS get_toolbar_object
      EXPORTING
        er_toolbar TYPE REF TO cl_gui_toolbar.

    METHODS get_selected_columns
      EXPORTING
        et_sel_columns TYPE any.

    METHODS set_default_drop
      IMPORTING
        i_drag_drop TYPE REF TO cl_dragdrop
      EXCEPTIONS
        cntl_system_error
        failed
        invalid_drag_drop_obj.

    METHODS frontend_update.

  PROTECTED SECTION.

    DATA m_batch_mode TYPE sy-batch.
    DATA m_fcode TYPE sy-ucomm.
    DATA m_item_selection TYPE abap_bool.
    DATA m_no_html_header TYPE abap_bool.
    DATA m_no_toolbar TYPE abap_bool.
    DATA m_node_selection_mode TYPE i.

    DATA mr_column_tree TYPE REF TO cl_gui_column_tree.
    DATA mr_toolbar TYPE REF TO cl_gui_toolbar.
    DATA mr_default_drop TYPE REF TO cl_dragdrop.

    DATA ms_exception_field TYPE lvc_s_l004.
    DATA ms_layout TYPE lvc_s_layo.
    DATA ms_hierarchy_header TYPE treev_hhdr.
    DATA mt_calculated_items TYPE HASHED TABLE OF lvc_s_item WITH UNIQUE KEY node_key item_name.
    DATA mt_checked_items TYPE lvc_t_chit.
    DATA mt_fieldcatalog TYPE lvc_t_fcat.
    DATA mt_filter TYPE lvc_t_filt.
    DATA mt_filter_index TYPE lvc_t_fidx.
    DATA mt_index_outtab TYPE lvc_t_iton.
    DATA mt_item_layout TYPE lvc_t_lyin.
    DATA mt_list_commentary TYPE slis_t_listheader.
    DATA mt_outtab TYPE REF TO data.
    DATA mt_simple_hierarchy_data TYPE HASHED TABLE OF lvc_s_item WITH UNIQUE KEY node_key item_name.
    DATA mt_sort TYPE lvc_t_sort.
    DATA mt_special_groups TYPE lvc_t_sgrp.
    DATA mt_toolbar TYPE ttb_button.
    DATA mt_toolbar_excluding TYPE ui_functions.

    TYPES: BEGIN OF ty_html_node,
             node_key   TYPE string,
             parent_key TYPE string,
             text       TYPE string,
             expanded   TYPE abap_bool,
             selected   TYPE abap_bool,
           END OF ty_html_node.
    TYPES ty_html_nodes TYPE STANDARD TABLE OF ty_html_node WITH DEFAULT KEY.
    DATA mt_html_nodes TYPE ty_html_nodes.
    DATA mv_html_top_node TYPE string.

    EVENTS after_user_command
      EXPORTING
      VALUE(ucomm) TYPE sy-ucomm.

    METHODS create_report_header
      IMPORTING
        it_list_commentary    TYPE slis_t_listheader
        i_logo                TYPE sdydo_value OPTIONAL
        i_background_id       TYPE sdydo_key OPTIONAL
        i_set_splitter_height TYPE abap_bool OPTIONAL
        i_model_mode          TYPE abap_bool OPTIONAL.

    METHODS set_toolbar_buttons.

    METHODS add_column
      IMPORTING
        i_column TYPE lvc_fname
      EXCEPTIONS
        column_not_found
        too_many_columns.

    METHODS authority_check.

    METHODS set_first_fieldcatalog
      IMPORTING
      i_structure_name   TYPE any OPTIONAL
      is_variant         TYPE disvariant OPTIONAL
      i_save             TYPE abap_bool OPTIONAL
      i_default          TYPE abap_bool OPTIONAL
      it_sort            TYPE lvc_t_sort OPTIONAL
      it_filter          TYPE lvc_t_filt OPTIONAL
      is_layout          TYPE lvc_s_layo OPTIONAL
      it_specific_groups TYPE lvc_t_sgrp OPTIONAL
      CHANGING
      it_fieldcatalog    TYPE lvc_t_fcat OPTIONAL
      EXCEPTIONS
      exception_field_not_found
      invalid_parameter_combination
      program_error.

    METHODS set_fieldcatalog
      IMPORTING
        it_fieldcatalog TYPE lvc_t_fcat.

    METHODS add_model_node
      IMPORTING
        i_relat_node_key TYPE lvc_nkey
        i_relationship   TYPE int4
        is_node_layout   TYPE any OPTIONAL
        it_item_layout   TYPE any OPTIONAL
        i_node_text      TYPE lvc_value OPTIONAL
        i_index_outtab   TYPE sy-tabix
      EXPORTING
        e_new_node_key   TYPE lvc_nkey
      EXCEPTIONS
        node_not_found
        relat_node_not_found.

    METHODS vroot_children_to_queue.

    METHODS calculate_subtree
      IMPORTING
        i_node_key         TYPE lvc_nkey
      EXPORTING
        es_calculated_line TYPE any
        i_leafcount        TYPE i
      EXCEPTIONS
        program_error.

    METHODS apply_filter
      EXCEPTIONS
        program_error.

    METHODS tree_init
      EXCEPTIONS
        error.

    METHODS set_filter
      IMPORTING
      it_filter TYPE lvc_t_filt
      EXCEPTIONS
      no_fieldcatalog_available.

    METHODS add_children_to_control
      IMPORTING
        i_node   TYPE lvc_nkey
      EXPORTING
        e_change TYPE c.

    METHODS set_item_context_menu
      IMPORTING
        i_node_key  TYPE lvc_nkey
        i_fieldname TYPE lvc_fname
      CHANGING
        c_menu      TYPE REF TO cl_ctmenu.

    METHODS update_checked_items
      IMPORTING
        i_node_key  TYPE lvc_nkey
        i_fieldname TYPE lvc_fname
        i_checked   TYPE abap_bool
      EXCEPTIONS
        program_error.

    METHODS set_children_at_front
      IMPORTING
        i_node_key TYPE lvc_nkey
      EXCEPTIONS
        node_not_found.

    METHODS add_subtree_to_control
      IMPORTING
        i_node_key    TYPE lvc_nkey
        i_level_count TYPE i OPTIONAL.

    METHODS ensure_node_in_control_int
      IMPORTING
        i_node_key TYPE lvc_nkey
      EXCEPTIONS
        node_not_found.

    METHODS get_node_key_from_index
      IMPORTING
        i_index    TYPE lvc_index
      EXPORTING
        e_node_key TYPE lvc_nkey
      EXCEPTIONS
        index_not_found.

    METHODS tree_get_first_leafe
      IMPORTING
        i_node_key TYPE lvc_nkey
      EXPORTING
        e_node_key TYPE lvc_nkey
      EXCEPTIONS
        node_not_found.

    METHODS tree_get_parent
      IMPORTING
        i_node_key        TYPE lvc_nkey
      EXPORTING
        e_parent_node_key TYPE lvc_nkey.

    METHODS tree_node_has_children
      IMPORTING
        i_node_key     TYPE lvc_nkey
      EXPORTING
        e_has_children TYPE c
      EXCEPTIONS
        node_key_not_found.

    METHODS get_index_from_node_key
      IMPORTING
        i_node_key TYPE lvc_nkey
      EXPORTING
        e_index    TYPE lvc_index
      EXCEPTIONS
        node_not_found.

    METHODS change_line
      IMPORTING
        i_node_key     TYPE lvc_nkey
        i_outtab_line  TYPE any OPTIONAL
        is_node_layout TYPE any OPTIONAL
        it_item_layout TYPE any OPTIONAL
        i_node_text    TYPE any OPTIONAL
        i_u_node_text  TYPE any OPTIONAL
      EXCEPTIONS
        node_not_found.

    METHODS determine_icon_for_exception
      IMPORTING
        i_exception_value   TYPE any
      EXPORTING
        VALUE(e_icon_value) TYPE tv_image.

    METHODS tree_get_children
      IMPORTING
        i_node_key  TYPE lvc_nkey
      EXPORTING
        et_children TYPE lvc_t_nkey
      EXCEPTIONS
        historic_error
        node_key_not_found.

    METHODS handle_generic_functions
      IMPORTING
        i_fcode         TYPE sy-ucomm OPTIONAL
        it_node_key     TYPE lvc_t_nkey OPTIONAL
        i_fieldname     TYPE lvc_fname OPTIONAL
      EXPORTING
        e_event_handled TYPE c.

    METHODS set_node_context_menu
      IMPORTING
        i_node_key TYPE lvc_nkey
      CHANGING
        c_menu     TYPE REF TO cl_ctmenu.

    METHODS add_html_node
      IMPORTING
        node_key   TYPE string
        parent_key TYPE string OPTIONAL
        text       TYPE string OPTIONAL.

    METHODS refresh_tree_html.

    METHODS set_html_node_state
      IMPORTING
        node_key TYPE string
        expanded TYPE abap_bool OPTIONAL
        selected TYPE abap_bool OPTIONAL.

    METHODS clear_html_nodes.

    METHODS tree_html
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.

ENDCLASS.

CLASS cl_alv_tree_base IMPLEMENTATION.
  METHOD authority_check.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_column.
    READ TABLE mt_fieldcatalog TRANSPORTING NO FIELDS
      WITH KEY fieldname = i_column.
    IF sy-subrc <> 0.
      APPEND VALUE #( fieldname = i_column ) TO mt_fieldcatalog.
    ENDIF.
  ENDMETHOD.

  METHOD set_toolbar_buttons.
    IF mr_toolbar IS BOUND.
      mr_toolbar->add_button_group( data_table = mt_toolbar ).
    ENDIF.
  ENDMETHOD.

  METHOD set_filter.
    mt_filter = it_filter.
  ENDMETHOD.

  METHOD set_fieldcatalog.
    mt_fieldcatalog = it_fieldcatalog.
  ENDMETHOD.

  METHOD set_first_fieldcatalog.
    IF it_fieldcatalog IS SUPPLIED.
      mt_fieldcatalog = it_fieldcatalog.
    ENDIF.
    IF it_sort IS SUPPLIED.
      mt_sort = it_sort.
    ENDIF.
    IF it_filter IS SUPPLIED.
      mt_filter = it_filter.
    ENDIF.
    IF is_layout IS SUPPLIED.
      ms_layout = is_layout.
    ENDIF.
  ENDMETHOD.

  METHOD create_report_header.
    mt_list_commentary = it_list_commentary.
    cl_gui_control=>set_payload( control = me
                                 payload = |Report header lines={ lines( mt_list_commentary ) }| ).
  ENDMETHOD.

  METHOD add_model_node.
    DATA lv_parent_key TYPE string.
    DATA lv_new_key TYPE string.

    IF i_relat_node_key IS NOT INITIAL.
      READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
        WITH KEY node_key = CONV string( i_relat_node_key ).
      IF sy-subrc <> 0 AND i_relat_node_key <> c_virtual_root_node.
        RAISE relat_node_not_found.
      ENDIF.
      lv_parent_key = CONV string( i_relat_node_key ).
    ENDIF.

    lv_new_key = |MODEL-{ lines( mt_html_nodes ) + 1 }|.
    WHILE line_exists( mt_html_nodes[ node_key = lv_new_key ] ).
      lv_new_key = |MODEL-{ lines( mt_html_nodes ) + 1 }-{ sy-index }|.
    ENDWHILE.
    add_html_node(
      node_key   = lv_new_key
      parent_key = lv_parent_key
      text       = COND #( WHEN i_node_text IS SUPPLIED AND i_node_text IS NOT INITIAL
                            THEN CONV string( i_node_text )
                            ELSE lv_new_key ) ).
    APPEND VALUE #( ) TO mt_index_outtab.
    e_new_node_key = CONV lvc_nkey( lv_new_key ).
  ENDMETHOD.

  METHOD vroot_children_to_queue.
    CLEAR mv_html_top_node.
    READ TABLE mt_html_nodes INTO DATA(ls_node) INDEX 1.
    IF sy-subrc = 0.
      mv_html_top_node = ls_node-node_key.
    ENDIF.
  ENDMETHOD.

  METHOD calculate_subtree.
    DATA lt_pending TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_pending TYPE string.
    DATA lv_has_child TYPE abap_bool.
    CLEAR i_leafcount.
    APPEND CONV string( i_node_key ) TO lt_pending.
    WHILE lt_pending IS NOT INITIAL.
      READ TABLE lt_pending INTO lv_pending INDEX 1.
      DELETE lt_pending INDEX 1.
      lv_has_child = abap_false.
      LOOP AT mt_html_nodes INTO DATA(ls_child)
          WHERE parent_key = lv_pending.
        lv_has_child = abap_true.
        APPEND ls_child-node_key TO lt_pending.
      ENDLOOP.
      IF lv_has_child = abap_false.
        i_leafcount = i_leafcount + 1.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD apply_filter.
    cl_gui_control=>set_payload( control = me
                                 payload = |Tree filter rows={ lines( mt_filter ) }| ).
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD tree_init.
    vroot_children_to_queue( ).
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD set_node_context_menu.
    RAISE EVENT node_context_menu_request
      EXPORTING
        node_key = i_node_key
        menu     = c_menu.
  ENDMETHOD.

  METHOD set_hierarchy_help_fields.
    IF i_doktitle IS SUPPLIED.
      ms_hierarchy_header-heading = i_doktitle.
    ENDIF.
    IF i_ref_field IS SUPPLIED.
      ms_hierarchy_header-tooltip = i_ref_field.
    ENDIF.
    cl_gui_control=>set_payload(
      control = me
      payload = |Hierarchy help field={ i_ref_field } title={ i_doktitle }| ).
  ENDMETHOD.

  METHOD handle_generic_functions.
    CLEAR e_event_handled.
    IF i_fcode IS INITIAL.
      RETURN.
    ENDIF.
    m_fcode = i_fcode.
    e_event_handled = xsdbool(
      i_fcode = mc_fc_calculate OR
      i_fcode = mc_fc_calculate_avg OR
      i_fcode = mc_fc_calculate_max OR
      i_fcode = mc_fc_calculate_min OR
      i_fcode = mc_fc_calculate_sum ).
    RAISE EVENT after_user_command EXPORTING ucomm = i_fcode.
  ENDMETHOD.

  METHOD set_item_context_menu.
    RAISE EVENT node_context_menu_request
      EXPORTING
        node_key = i_node_key
        menu     = c_menu.
  ENDMETHOD.

  METHOD add_children_to_control.
    CLEAR e_change.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = CONV string( i_node ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    e_change = xsdbool( line_exists( mt_html_nodes[ parent_key = CONV string( i_node ) ] ) ).
    IF e_change = 'X'.
      add_subtree_to_control( i_node_key = i_node ).
    ENDIF.
  ENDMETHOD.

  METHOD set_children_at_front.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc <> 0.
      RAISE node_not_found.
    ENDIF.
    DELETE mt_html_nodes INDEX sy-tabix.
    INSERT ls_node INTO mt_html_nodes INDEX 1.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD update_checked_items.
    DELETE mt_checked_items WHERE nodekey = i_node_key
                              AND fieldname = i_fieldname.
    IF i_checked = abap_true.
      APPEND VALUE #( nodekey   = i_node_key
                      fieldname = i_fieldname ) TO mt_checked_items.
    ENDIF.
  ENDMETHOD.

  METHOD add_subtree_to_control.
    ensure_node_in_control_int( i_node_key ).
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD ensure_node_in_control_int.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc <> 0.
      RAISE node_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD tree_node_has_children.
    CLEAR e_has_children.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc <> 0.
      RAISE node_key_not_found.
    ENDIF.
    e_has_children = xsdbool(
      line_exists( mt_html_nodes[ parent_key = CONV string( i_node_key ) ] ) ).
  ENDMETHOD.

  METHOD tree_get_first_leafe.
    DATA lt_pending TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_pending TYPE string.
    DATA lv_has_child TYPE abap_bool.
    APPEND CONV string( i_node_key ) TO lt_pending.
    WHILE lt_pending IS NOT INITIAL.
      READ TABLE lt_pending INTO lv_pending INDEX 1.
      DELETE lt_pending INDEX 1.
      READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
        WITH KEY node_key = lv_pending.
      IF sy-subrc <> 0.
        RAISE node_not_found.
      ENDIF.
      lv_has_child = abap_false.
      LOOP AT mt_html_nodes INTO DATA(ls_child)
          WHERE parent_key = lv_pending.
        lv_has_child = abap_true.
        APPEND ls_child-node_key TO lt_pending.
      ENDLOOP.
      IF lv_has_child = abap_false.
        e_node_key = CONV lvc_nkey( lv_pending ).
        RETURN.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD tree_get_parent.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc = 0.
      e_parent_node_key = CONV lvc_nkey( ls_node-parent_key ).
    ENDIF.
  ENDMETHOD.

  METHOD tree_get_children.
    LOOP AT mt_html_nodes INTO DATA(ls_node)
        WHERE parent_key = CONV string( i_node_key ).
      APPEND CONV lvc_nkey( ls_node-node_key ) TO et_children.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_index_from_node_key.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc = 0.
      e_index = sy-tabix.
    ENDIF.
  ENDMETHOD.

  METHOD frontend_update.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD determine_icon_for_exception.
    e_icon_value = '@5B@'.
  ENDMETHOD.

  METHOD change_line.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( i_node_key ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF i_node_text IS SUPPLIED.
      ls_node-text = CONV string( i_node_text ).
    ENDIF.
    MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD get_node_key_from_index.
    READ TABLE mt_html_nodes INTO DATA(ls_node) INDEX i_index.
    IF sy-subrc = 0.
      e_node_key = CONV lvc_nkey( ls_node-node_key ).
    ENDIF.
  ENDMETHOD.

  METHOD set_default_drop.
    DATA lv_handle TYPE i.
    IF i_drag_drop IS NOT BOUND.
      RAISE invalid_drag_drop_obj.
    ENDIF.
    mr_default_drop = i_drag_drop.
    i_drag_drop->get_handle( IMPORTING handle = lv_handle ).
    cl_gui_control=>set_payload( control = me
                                 payload = |Default drag/drop handle={ lv_handle }| ).
  ENDMETHOD.

  METHOD get_registered_events.
    CLEAR events.
  ENDMETHOD.

  METHOD get_selected_columns.
    FIELD-SYMBOLS <columns> TYPE ANY TABLE.
    ASSIGN et_sel_columns TO <columns>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT mt_fieldcatalog INTO DATA(ls_field).
      APPEND ls_field-fieldname TO <columns>.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_toolbar_object.
    IF mr_toolbar IS NOT BOUND AND parent IS BOUND.
      mr_toolbar = NEW cl_gui_toolbar( parent = parent ).
      set_toolbar_buttons( ).
    ENDIF.
    er_toolbar = mr_toolbar.
  ENDMETHOD.

  METHOD column_optimize.
    cl_gui_control=>set_payload( control = me
                                 payload = |Tree columns optimized; fields={ lines( mt_fieldcatalog ) }| ).
  ENDMETHOD.

  METHOD update_calculations.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_frontend_fieldcatalog.
    et_fieldcatalog = mt_fieldcatalog.
  ENDMETHOD.

  METHOD add_html_node.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = node_key.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    APPEND VALUE #( node_key   = node_key
                    parent_key = parent_key
                    text       = text
                    expanded   = abap_true ) TO mt_html_nodes.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD refresh_tree_html.
    cl_gui_control=>set_html( control = me
                              html    = tree_html( ) ).
  ENDMETHOD.

  METHOD tree_html.
    DATA lv_depth TYPE i.
    DATA lv_parent TYPE string.
    result = |<ul role="tree" aria-label="ALV tree">|.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      lv_depth = 1.
      lv_parent = ls_node-parent_key.
      DO 32 TIMES.
        IF lv_parent IS INITIAL.
          EXIT.
        ENDIF.
        READ TABLE mt_html_nodes INTO DATA(ls_parent)
          WITH KEY node_key = lv_parent.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        lv_depth = lv_depth + 1.
        lv_parent = ls_parent-parent_key.
      ENDDO.
      DATA(lv_state_class) = cl_gui_control=>state_class( iv_selected = ls_node-selected ).
      DATA(lv_selected) = COND string(
        WHEN ls_node-selected = abap_true THEN ' aria-current="true" aria-selected="true"'
        ELSE ' aria-selected="false"' ).
      DATA(lv_expanded) = COND string( WHEN ls_node-expanded = abap_true THEN 'true' ELSE 'false' ).
      result = result && |<li class="gg-tree-node { lv_state_class }" role="treeitem" tabindex="0" aria-level="{ lv_depth }" aria-expanded="{ lv_expanded }" data-node-key="{ escape_html( ls_node-node_key ) }" data-parent-key="{ escape_html( ls_node-parent_key ) }"{ lv_selected }>{ escape_html( ls_node-text ) }</li>|.
    ENDLOOP.
    result = result && |</ul>|.
  ENDMETHOD.

  METHOD set_html_node_state.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = node_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF expanded IS SUPPLIED.
      ls_node-expanded = expanded.
    ENDIF.
    IF selected IS SUPPLIED.
      ls_node-selected = selected.
    ENDIF.
    MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD clear_html_nodes.
    CLEAR mt_html_nodes.
    refresh_tree_html( ).
  ENDMETHOD.

ENDCLASS.
