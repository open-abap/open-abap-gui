CLASS cl_alv_tree_base DEFINITION PUBLIC INHERITING FROM cl_gui_control
  FRIENDS cl_gui_cfw cl_gui_alv_tree zcl_gg_host_runtime.
  PUBLIC SECTION.
    TYPES ty_instances TYPE STANDARD TABLE OF REF TO cl_alv_tree_base WITH DEFAULT KEY.

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

    METHODS free REDEFINITION.

  PROTECTED SECTION.
    METHODS dispatch_frontend_event REDEFINITION.
    METHODS is_application_event REDEFINITION.

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
             node_key     TYPE string,
             parent_key   TYPE string,
             text         TYPE string,
             expanded     TYPE abap_bool,
             selected     TYPE abap_bool,
             has_children TYPE abap_bool,
             is_folder    TYPE abap_bool,
             node_image   TYPE string,
             open_image   TYPE string,
             item_layout  TYPE lvc_t_layi,
             data_row     TYPE REF TO data,
           END OF ty_html_node.
    TYPES ty_html_nodes TYPE STANDARD TABLE OF ty_html_node WITH DEFAULT KEY.
    TYPES ty_node_keys TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA mt_html_nodes TYPE ty_html_nodes.
    DATA mv_html_top_node TYPE string.
    DATA mv_find_text TYPE string.
    DATA mv_search_dialog TYPE string.
    DATA mt_search_input TYPE zcl_gg_gui_runtime=>ty_fields.
    TYPES: BEGIN OF ty_html_column_width,
             fieldname TYPE string,
             width     TYPE i,
           END OF ty_html_column_width.
    TYPES ty_html_column_widths TYPE STANDARD TABLE OF ty_html_column_width WITH DEFAULT KEY.

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
        node_key       TYPE string
        parent_key     TYPE string OPTIONAL
        text           TYPE string OPTIONAL
        data_row       TYPE any OPTIONAL
        has_children   TYPE abap_bool OPTIONAL
        is_folder      TYPE abap_bool OPTIONAL
        node_image     TYPE string OPTIONAL
        open_image     TYPE string OPTIONAL
        it_item_layout TYPE lvc_t_layi OPTIONAL.

    METHODS refresh_tree_html.

    METHODS receive_frontend_values REDEFINITION.

    METHODS on_toolbar_function
      FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.

    METHODS search_input
      IMPORTING key           TYPE string
      RETURNING VALUE(result) TYPE string.

    METHODS render_search_dialog
      RETURNING VALUE(result) TYPE string.

    METHODS node_field_text
      IMPORTING
        is_node               TYPE ty_html_node
        fieldname             TYPE lvc_fname
      RETURNING VALUE(result) TYPE string.

    METHODS node_matches_filter
      IMPORTING is_node       TYPE ty_html_node
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS node_contains_text
      IMPORTING is_node       TYPE ty_html_node
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS reveal_find_matches.

    METHODS reveal_filter_matches.

    METHODS expand_ancestors
      IMPORTING parent_key TYPE string.

    METHODS filter_visible_keys
      RETURNING VALUE(result) TYPE ty_node_keys.

    METHODS set_html_node_state
      IMPORTING
        node_key TYPE string
        expanded TYPE abap_bool OPTIONAL
        selected TYPE abap_bool OPTIONAL.

    METHODS clear_html_nodes.

    "! Walks the ancestor chain of NODE_KEY once and answers both questions the
    "! rendered tree asks about a node: LEVEL is 1 for a root node and one more
    "! per ancestor still present in the node table, VISIBLE is false when any
    "! of those ancestors is collapsed.
    METHODS node_position
      IMPORTING
        node_key TYPE string
      EXPORTING
        level    TYPE i
        visible  TYPE abap_bool.

    METHODS tree_html
      RETURNING
        VALUE(result) TYPE string.

    METHODS html_column_widths
      RETURNING
        VALUE(result) TYPE ty_html_column_widths.

    METHODS handle_browser_event
      IMPORTING
        event         TYPE string
        node_key      TYPE string OPTIONAL
        fieldname     TYPE string OPTIONAL
        value         TYPE string OPTIONAL
        checked       TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.

    CLASS-METHODS register_instance
      IMPORTING
        control TYPE REF TO cl_alv_tree_base.

    CLASS-METHODS unregister_instance
      IMPORTING
        control TYPE REF TO cl_alv_tree_base.

    CLASS-METHODS clear_instances.

    CLASS-METHODS save_instances
      RETURNING
        VALUE(result) TYPE ty_instances.

    CLASS-METHODS restore_instances
      IMPORTING
        instances TYPE ty_instances.

    CLASS-METHODS dispatch_browser_event
      IMPORTING
        event         TYPE string
        node_key      TYPE string OPTIONAL
        fieldname     TYPE string OPTIONAL
        value         TYPE string OPTIONAL
        checked       TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-DATA mt_instances TYPE ty_instances.

ENDCLASS.

CLASS cl_alv_tree_base IMPLEMENTATION.
  METHOD is_application_event.
    result = xsdbool( event <> 'SEARCH' ).
  ENDMETHOD.

  METHOD dispatch_frontend_event.
    handle_browser_event( event    = event
                          node_key = VALUE #( params[ 1 ] OPTIONAL )
      fieldname                    = VALUE #( params[ 2 ] OPTIONAL )
                          value    = VALUE #( params[ 3 ] OPTIONAL )
      checked                      = xsdbool( VALUE string( params[ 4 ] OPTIONAL ) = 'X' ) ).
  ENDMETHOD.

  METHOD register_instance.
    IF control IS BOUND.
      APPEND control TO mt_instances.
    ENDIF.
  ENDMETHOD.

  METHOD unregister_instance.
    DELETE mt_instances WHERE table_line = control.
  ENDMETHOD.

  METHOD clear_instances.
    CLEAR mt_instances.
  ENDMETHOD.

  METHOD save_instances.
    result = mt_instances.
  ENDMETHOD.

  METHOD restore_instances.
    mt_instances = instances.
  ENDMETHOD.

  METHOD dispatch_browser_event.
    DATA lv_handled TYPE abap_bool.
    CLEAR result.
    DATA(lv_instance_index) = lines( mt_instances ).
    WHILE lv_instance_index > 0.
      READ TABLE mt_instances INTO DATA(lo_instance) INDEX lv_instance_index.
      IF lo_instance IS BOUND.
        lv_handled = lo_instance->handle_browser_event(
          event     = event
          node_key  = node_key
          fieldname = fieldname
          value     = value
          checked   = checked ).
        IF lv_handled = abap_true.
          result = abap_true.
        ENDIF.
      ENDIF.
      lv_instance_index = lv_instance_index - 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD free.
    unregister_instance( me ).
    super->free( ).
  ENDMETHOD.

  METHOD handle_browser_event.
    DATA lt_selected_keys TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    CLEAR result.
    CASE event.
      WHEN 'TREE_SELECT'.
        LOOP AT mt_html_nodes INTO DATA(ls_selected_node).
          ls_selected_node-selected = abap_false.
          MODIFY mt_html_nodes FROM ls_selected_node INDEX sy-tabix.
        ENDLOOP.
        IF value IS INITIAL.
          APPEND node_key TO lt_selected_keys.
        ELSE.
          SPLIT value AT ',' INTO TABLE lt_selected_keys.
        ENDIF.
        LOOP AT lt_selected_keys INTO DATA(lv_selected_key).
          IF lv_selected_key IS INITIAL.
            CONTINUE.
          ENDIF.
          READ TABLE mt_html_nodes INTO ls_selected_node
            WITH KEY node_key = lv_selected_key.
          IF sy-subrc = 0.
            ls_selected_node-selected = abap_true.
            MODIFY mt_html_nodes FROM ls_selected_node INDEX sy-tabix.
          ENDIF.
        ENDLOOP.
        refresh_tree_html( ).
        result = abap_true.
      WHEN 'TREE_TOGGLE'.
        set_html_node_state(
          node_key = node_key
          expanded = xsdbool( value = 'true' OR value = 'X' OR value = '1' ) ).
        result = abap_true.
      WHEN 'COMMAND'.
        CASE value.
          WHEN '&REFRESH'.
            refresh_tree_html( ).
            result = abap_true.
          WHEN OTHERS.
            RETURN.
        ENDCASE.
      WHEN 'SEARCH'.
        CASE node_key.
          WHEN 'APPLY'.
            CASE mv_search_dialog.
              WHEN 'FIND'.
                mv_find_text = search_input( 'term' ).
                reveal_find_matches( ).
              WHEN 'FILTER'.
                DATA(lv_fieldname) = CONV lvc_fname( search_input( 'field' ) ).
                IF lv_fieldname = c_hierarchy_column_name
                    OR line_exists( mt_fieldcatalog[ fieldname = lv_fieldname tech = space no_out = space ] ).
                  DELETE mt_filter WHERE fieldname = lv_fieldname.
                  IF search_input( 'term' ) IS NOT INITIAL.
                    APPEND VALUE #( fieldname = lv_fieldname sign = 'I'
                      option = search_input( 'option' ) low = search_input( 'term' ) ) TO mt_filter.
                  ENDIF.
                ENDIF.
                reveal_filter_matches( ).
            ENDCASE.
          WHEN 'CLEAR'.
            CASE mv_search_dialog.
              WHEN 'FILTER'.
                CLEAR mt_filter.
              WHEN 'FIND'.
                CLEAR mv_find_text.
            ENDCASE.
        ENDCASE.
        CLEAR: mv_search_dialog, mt_search_input.
        refresh_tree_html( ).
        result = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD receive_frontend_values.
    mt_search_input = values.
  ENDMETHOD.

  METHOD on_toolbar_function.
    CASE fcode.
      WHEN '&FIND'.
        mv_search_dialog = 'FIND'.
      WHEN '&FILTER'.
        mv_search_dialog = 'FILTER'.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
    CLEAR mt_search_input.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD search_input.
    READ TABLE mt_search_input INTO DATA(ls_input) WITH KEY name = key.
    IF sy-subrc = 0.
      result = ls_input-value.
    ENDIF.
  ENDMETHOD.

  METHOD render_search_dialog.
    IF mv_search_dialog IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_body) = ``.
    IF mv_search_dialog = 'FILTER'.
      lv_body = |<label>Column <select name="{ frontend_field_name( 'field' ) }"><option value="{ zcl_gg_gui_runtime=>escape_html( CONV string( c_hierarchy_column_name ) ) }">Hierarchy</option>|.
      LOOP AT mt_fieldcatalog INTO DATA(ls_fieldcat)
          WHERE tech IS INITIAL AND no_out IS INITIAL.
        DATA(lv_heading) = COND string(
          WHEN ls_fieldcat-coltext IS NOT INITIAL THEN CONV string( ls_fieldcat-coltext )
          ELSE CONV string( ls_fieldcat-fieldname ) ).
        lv_body = lv_body && |<option value="{ zcl_gg_gui_runtime=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }">{ zcl_gg_gui_runtime=>escape_html( lv_heading ) }</option>|.
      ENDLOOP.
      lv_body = lv_body && |</select></label><label>Comparison <select name="{ frontend_field_name( 'option' ) }"><option>EQ</option><option>NE</option><option>CP</option><option>GE</option><option>LE</option></select></label>|.
    ENDIF.
    lv_body = lv_body && |<label>Text <input name="{ frontend_field_name( 'term' ) }" type="text" value="{ COND string( WHEN mv_search_dialog = 'FIND' THEN zcl_gg_gui_runtime=>escape_html( mv_find_text ) ELSE `` ) }"></label>|.
    DATA(lv_apply) = frontend_event_value( event  = 'SEARCH'
                                           params = VALUE #( ( `APPLY` ) ) ).
    DATA(lv_clear) = frontend_event_value( event  = 'SEARCH'
                                           params = VALUE #( ( `CLEAR` ) ) ).
    DATA(lv_cancel) = frontend_event_value( event  = 'SEARCH'
                                            params = VALUE #( ( `CANCEL` ) ) ).
    DATA(lv_clear_button) = COND string(
      WHEN mv_search_dialog = 'FILTER' AND mt_filter IS NOT INITIAL
        OR mv_search_dialog = 'FIND' AND mv_find_text IS NOT INITIAL
      THEN |<button type="submit" name="gg_control_event" value="{ lv_clear }" formnovalidate>Clear</button>|
      ELSE `` ).
    result = |<section class="gg-alv-layout-dialog" role="dialog" aria-label="{ mv_search_dialog }"><h3>{ mv_search_dialog }</h3>{ lv_body }<footer><button type="submit" name="gg_control_event" value="{ lv_apply }" formnovalidate>Apply</button>{ lv_clear_button }<button type="submit" name="gg_control_event" value="{ lv_cancel }" formnovalidate>Cancel</button></footer></section>|.
  ENDMETHOD.

  METHOD node_field_text.
    IF fieldname = c_hierarchy_column_name.
      result = is_node-text.
      RETURN.
    ENDIF.
    READ TABLE mt_fieldcatalog INTO DATA(ls_fieldcat)
      WITH KEY fieldname = fieldname.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF is_node-data_row IS BOUND.
      ASSIGN is_node-data_row->* TO FIELD-SYMBOL(<row>).
      IF sy-subrc = 0.
        ASSIGN COMPONENT fieldname OF STRUCTURE <row> TO FIELD-SYMBOL(<component>).
        IF sy-subrc = 0.
          result = cl_gui_control=>format_external_value(
            iv_value = |{ <component> }|
            iv_type  = CONV string( ls_fieldcat-inttype ) ).
        ENDIF.
      ENDIF.
    ELSEIF ls_fieldcat-do_sum = abap_true.
      result = '0'.
    ENDIF.
  ENDMETHOD.

  METHOD node_matches_filter.
    result = abap_true.
    LOOP AT mt_filter INTO DATA(ls_filter).
      IF ls_filter-fieldname <> c_hierarchy_column_name
          AND NOT line_exists( mt_fieldcatalog[ fieldname = ls_filter-fieldname tech = space no_out = space ] ).
        result = abap_false.
        RETURN.
      ENDIF.
      DATA(lv_low) = CONV string( ls_filter-low ).
      DATA(lv_high) = CONV string( ls_filter-high ).
      SHIFT lv_low RIGHT DELETING TRAILING space.
      SHIFT lv_low LEFT DELETING LEADING space.
      SHIFT lv_high RIGHT DELETING TRAILING space.
      SHIFT lv_high LEFT DELETING LEADING space.
      IF cl_gui_control=>compare_option(
          iv_value         = node_field_text( is_node = is_node fieldname = ls_filter-fieldname )
          iv_option        = CONV string( ls_filter-option )
          iv_low           = lv_low
          iv_high          = lv_high
          iv_sign          = CONV string( ls_filter-sign )
          iv_unknown_as_eq = abap_true ) = abap_false.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD node_contains_text.
    IF mv_find_text IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_term) = to_upper( mv_find_text ).
    IF to_upper( is_node-text ) CS lv_term.
      result = abap_true.
      RETURN.
    ENDIF.
    LOOP AT mt_fieldcatalog INTO DATA(ls_fieldcat)
        WHERE tech IS INITIAL AND no_out IS INITIAL.
      DATA(lv_value) = node_field_text(
        is_node   = is_node
        fieldname = ls_fieldcat-fieldname ).
      IF to_upper( lv_value ) CS lv_term.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD reveal_find_matches.
    IF mv_find_text IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT mt_html_nodes INTO DATA(ls_match).
      IF node_contains_text( ls_match ) = abap_false.
        CONTINUE.
      ENDIF.
      expand_ancestors( ls_match-parent_key ).
    ENDLOOP.
  ENDMETHOD.

  METHOD reveal_filter_matches.
    IF mt_filter IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT mt_html_nodes INTO DATA(ls_match).
      IF node_matches_filter( ls_match ) = abap_true.
        expand_ancestors( ls_match-parent_key ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD expand_ancestors.
    DATA(lv_parent_key) = parent_key.
    DO 32 TIMES.
      READ TABLE mt_html_nodes INTO DATA(ls_parent)
        WITH KEY node_key = lv_parent_key.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      ls_parent-expanded = abap_true.
      MODIFY mt_html_nodes FROM ls_parent INDEX sy-tabix.
      lv_parent_key = ls_parent-parent_key.
    ENDDO.
  ENDMETHOD.

  METHOD filter_visible_keys.
    IF mt_filter IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT mt_html_nodes INTO DATA(ls_match).
      IF node_matches_filter( ls_match ) = abap_false.
        CONTINUE.
      ENDIF.
      DATA(lv_path_key) = ls_match-node_key.
      DO 32 TIMES.
        INSERT lv_path_key INTO TABLE result.
        READ TABLE mt_html_nodes INTO DATA(ls_ancestor)
          WITH KEY node_key = lv_path_key.
        IF sy-subrc <> 0 OR ls_ancestor-parent_key IS INITIAL.
          EXIT.
        ENDIF.
        lv_path_key = ls_ancestor-parent_key.
      ENDDO.
    ENDLOOP.
  ENDMETHOD.

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
      IF mt_toolbar IS INITIAL.
        mt_toolbar = VALUE #(
          ( function = '&FILTER' icon = 'search-plus' butn_type = 0 quickinfo = 'Filter' )
          ( function = '&SORT_ASC' icon = 'arrow-bar-to-up' butn_type = 0 disabled = abap_true quickinfo = 'Sort unavailable for hierarchical rows' )
          ( function = '&FIND' icon = 'binoculars' butn_type = 0 quickinfo = 'Find' )
          ( function = '&SUMC' icon = 'database' butn_type = 0 disabled = abap_true quickinfo = 'Use the report calculation action' )
          ( function = '&&SEP' icon = `` butn_type = 2 )
          ( function = '&PRINT' icon = 'printer' butn_type = 0 disabled = abap_true quickinfo = 'Print unavailable in browser' )
          ( function = '&VIEW' icon = 'device-desktop' butn_type = 0 disabled = abap_true quickinfo = 'Layout variants unavailable in browser' ) ).
        LOOP AT mt_toolbar INTO DATA(ls_toolbar_button).
          IF line_exists( mt_toolbar_excluding[ table_line = ls_toolbar_button-function ] ).
            DELETE mt_toolbar INDEX sy-tabix.
          ENDIF.
        ENDLOOP.
      ENDIF.
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
    reveal_filter_matches( ).
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
    IF i_doktitle IS SUPPLIED AND ms_hierarchy_header-heading IS INITIAL.
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
    DATA lt_events TYPE cntl_simple_events.
    IF mr_toolbar IS NOT BOUND AND parent IS BOUND AND m_no_toolbar = abap_false.
      mr_toolbar = NEW cl_gui_toolbar( parent = parent ).
      mr_toolbar->set_position( height = 32 ).
      APPEND VALUE #(
        eventid    = cl_gui_toolbar=>m_id_function_selected
        appl_event = abap_false ) TO lt_events.
      mr_toolbar->set_registered_events( lt_events ).
      SET HANDLER me->on_toolbar_function FOR mr_toolbar.
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
    DATA lr_data_row TYPE REF TO data.
    DATA ls_new_node TYPE ty_html_node.
    DATA lv_insert_index TYPE i.
    FIELD-SYMBOLS <data_row_copy> TYPE any.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = node_key.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
* The node keeps a copy of the line in the tree's output table;
* the caller's variable usually changes with the next node.
    IF data_row IS SUPPLIED.
      CREATE DATA lr_data_row LIKE data_row.
      ASSIGN lr_data_row->* TO <data_row_copy>.
      <data_row_copy> = data_row.
    ENDIF.
    ls_new_node = VALUE #( node_key     = node_key
                           parent_key   = parent_key
                           text         = text
                           expanded     = xsdbool( has_children = abap_false )
                           has_children = has_children
                           is_folder    = is_folder
                           node_image   = node_image
                           open_image   = open_image
                           item_layout  = it_item_layout
                           data_row     = lr_data_row ).
    IF parent_key IS INITIAL.
      APPEND ls_new_node TO mt_html_nodes.
    ELSE.
      READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
        WITH KEY node_key = parent_key.
      IF sy-subrc <> 0.
        APPEND ls_new_node TO mt_html_nodes.
      ELSE.
        lv_insert_index = sy-tabix + 1.
        WHILE lv_insert_index <= lines( mt_html_nodes ).
          READ TABLE mt_html_nodes INTO DATA(ls_candidate)
            INDEX lv_insert_index.
          DATA(lv_candidate_parent) = ls_candidate-parent_key.
          DATA(lv_is_descendant) = abap_false.
          DO 32 TIMES.
            IF lv_candidate_parent IS INITIAL.
              EXIT.
            ENDIF.
            IF lv_candidate_parent = parent_key.
              lv_is_descendant = abap_true.
              EXIT.
            ENDIF.
            READ TABLE mt_html_nodes INTO DATA(ls_ancestor)
              WITH KEY node_key = lv_candidate_parent.
            IF sy-subrc <> 0.
              EXIT.
            ENDIF.
            lv_candidate_parent = ls_ancestor-parent_key.
          ENDDO.
          IF lv_is_descendant = abap_false.
            EXIT.
          ENDIF.
          lv_insert_index = lv_insert_index + 1.
        ENDWHILE.
        INSERT ls_new_node INTO mt_html_nodes INDEX lv_insert_index.
      ENDIF.
    ENDIF.
    IF mt_filter IS NOT INITIAL AND node_matches_filter( ls_new_node ) = abap_true.
      expand_ancestors( parent_key ).
    ENDIF.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD refresh_tree_html.
    cl_gui_control=>set_html( control = me
                              html    = tree_html( ) ).
  ENDMETHOD.

  METHOD node_position.
    DATA lv_parent TYPE string.

    level = 1.
    visible = abap_true.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = node_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_parent = ls_node-parent_key.
* A node cannot be its own ancestor, but nothing stops a caller from building a
* cyclic parent chain, so the walk is bounded by the nesting the control shows.
    DO 32 TIMES.
      IF lv_parent IS INITIAL.
        RETURN.
      ENDIF.
      READ TABLE mt_html_nodes INTO DATA(ls_parent)
        WITH KEY node_key = lv_parent.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      level = level + 1.
      IF ls_parent-expanded = abap_false.
        visible = abap_false.
      ENDIF.
      lv_parent = ls_parent-parent_key.
    ENDDO.
  ENDMETHOD.

  METHOD html_column_widths.
    FIELD-SYMBOLS <column_row> TYPE any.
    FIELD-SYMBOLS <column_value> TYPE any.

    LOOP AT mt_fieldcatalog INTO DATA(ls_width_fieldcat).
      IF ls_width_fieldcat-no_out IS NOT INITIAL OR ls_width_fieldcat-tech IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      DATA(lv_width_heading) = COND string(
        WHEN ls_width_fieldcat-coltext IS INITIAL
          THEN CONV string( ls_width_fieldcat-fieldname )
        ELSE CONV string( ls_width_fieldcat-coltext ) ).
      DATA(lv_max_chars) = strlen( lv_width_heading ).
      LOOP AT mt_html_nodes INTO DATA(ls_width_node).
        IF ls_width_node-data_row IS NOT BOUND.
          CONTINUE.
        ENDIF.
        ASSIGN ls_width_node-data_row->* TO <column_row>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT ls_width_fieldcat-fieldname OF STRUCTURE <column_row>
          TO <column_value>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        DATA(lv_width_value) = |{ <column_value> }|.
        IF strlen( lv_width_value ) > lv_max_chars.
          lv_max_chars = strlen( lv_width_value ).
        ENDIF.
      ENDLOOP.
      DATA(lv_column_width) = lv_max_chars * 7 + 20.
      IF lv_column_width < 48.
        lv_column_width = 48.
      ENDIF.
      APPEND VALUE #( fieldname = CONV string( ls_width_fieldcat-fieldname )
                      width     = lv_column_width ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD tree_html.
    DATA lv_depth TYPE i.
    DATA lv_visible TYPE abap_bool.
    DATA ls_node TYPE ty_html_node.
    DATA(lt_filter_visible) = filter_visible_keys( ).
    DATA(lt_html_column_width) = html_column_widths( ).
    DATA(lv_hierarchy_width) = COND i(
      WHEN ms_hierarchy_header-width > 0
        THEN ( ms_hierarchy_header-width * 13 ) / 2
      ELSE 0 ).
    DATA(lv_hierarchy_style) = COND string(
      WHEN lv_hierarchy_width > 0 THEN | style="width:{ lv_hierarchy_width }px;min-width:{ lv_hierarchy_width }px;max-width:{ lv_hierarchy_width }px"|
      ELSE `` ).
    DATA(lv_table_width) = COND i(
      WHEN lv_hierarchy_width > 0 THEN lv_hierarchy_width ELSE 180 ).
    LOOP AT lt_html_column_width INTO DATA(ls_table_column_width).
      lv_table_width = lv_table_width + ls_table_column_width-width.
    ENDLOOP.
    IF mr_toolbar IS BOUND AND m_no_toolbar = abap_false.
      cl_gui_control=>set_payload(
        control = mr_toolbar
        payload = |toolbar-kind=ALV; buttons={ lines( mr_toolbar->m_table_button ) }| ).
    ENDIF.
    DATA(lv_toolbar_spacer) = COND string(
      WHEN mr_toolbar IS BOUND AND m_no_toolbar = abap_false
        THEN '<div class="gg-alv-tree-toolbar-spacer" aria-hidden="true" style="height:32px"></div>'
      ELSE `` ).
    DATA(lv_heading) = ms_hierarchy_header-heading.
    IF lv_heading IS INITIAL.
      lv_heading = 'Hierarchy'.
    ENDIF.
    result = |<section class="gg-alv-tree" aria-label="ALV tree">{ lv_toolbar_spacer }{ render_search_dialog( ) }<div class="gg-alv-tree-columns"><table role="tree" data-gg-control-id="{ zcl_gg_gui_runtime=>escape_html( control_id ) }" aria-label="ALV tree" data-field-count="{ lines( mt_fieldcatalog ) }" style="width:100%;min-width:{ lv_table_width }px;table-layout:fixed"><colgroup><col{ lv_hierarchy_style }/>|.
    LOOP AT mt_fieldcatalog INTO DATA(ls_col_fieldcat).
      IF ls_col_fieldcat-no_out IS INITIAL AND ls_col_fieldcat-tech IS INITIAL.
        READ TABLE lt_html_column_width INTO DATA(ls_col_width)
          WITH KEY fieldname = CONV string( ls_col_fieldcat-fieldname ).
        IF sy-subrc = 0.
          result = result && |<col style="width:{ ls_col_width-width }px;min-width:{ ls_col_width-width }px"/>|.
        ELSE.
          result = result && '<col />'.
        ENDIF.
      ENDIF.
    ENDLOOP.
    result = result && |<col style="width:auto"/></colgroup><thead><tr><th scope="col"{ lv_hierarchy_style }>{ zcl_gg_gui_runtime=>escape_html( CONV string( lv_heading ) ) }</th>|.
    LOOP AT mt_fieldcatalog INTO DATA(ls_fieldcat).
      IF ls_fieldcat-no_out IS INITIAL AND ls_fieldcat-tech IS INITIAL.
        result = result && |<th scope="col" data-fieldname="{ zcl_gg_gui_runtime=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }" data-inttype="{ zcl_gg_gui_runtime=>escape_html( CONV string( ls_fieldcat-inttype ) ) }">{ zcl_gg_gui_runtime=>escape_html( COND string( WHEN ls_fieldcat-coltext IS INITIAL THEN ls_fieldcat-fieldname ELSE ls_fieldcat-coltext ) ) }</th>|.
      ENDIF.
    ENDLOOP.
    result = result && '</tr></thead><tbody>'.
    LOOP AT mt_html_nodes INTO ls_node.
      IF mt_filter IS NOT INITIAL
          AND NOT line_exists( lt_filter_visible[ table_line = ls_node-node_key ] ).
        CONTINUE.
      ENDIF.
      node_position(
        EXPORTING
          node_key = ls_node-node_key
        IMPORTING
          level    = lv_depth
          visible  = lv_visible ).
      DATA(lv_has_children) = xsdbool(
        ls_node-has_children = abap_true
        OR line_exists( mt_html_nodes[ parent_key = ls_node-node_key ] ) ).
      DATA(lv_filtered_child) = abap_false.
      IF mt_filter IS NOT INITIAL.
        LOOP AT mt_html_nodes INTO DATA(ls_filter_child)
            WHERE parent_key = ls_node-node_key.
          IF line_exists( lt_filter_visible[ table_line = ls_filter_child-node_key ] ).
            lv_filtered_child = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lv_filtered_child = abap_false
            AND line_exists( mt_html_nodes[ parent_key = ls_node-node_key ] ).
          lv_has_children = abap_false.
        ENDIF.
      ENDIF.
      DATA(lv_is_expanded) = xsdbool(
        lv_has_children = abap_true
        AND ls_node-expanded = abap_true
        AND line_exists( mt_html_nodes[ parent_key = ls_node-node_key ] ) ).
      DATA(lv_tree_marker) = COND string(
        WHEN lv_has_children = abap_false THEN ``
        WHEN lv_is_expanded = abap_true THEN '&#9662;'
        ELSE '&#9656;' ).
      DATA(lv_icon_name) = COND string(
        WHEN ls_node-is_folder = abap_true OR lv_has_children = abap_true
          THEN COND string( WHEN lv_is_expanded = abap_true THEN 'folder-open' ELSE 'folder' )
        ELSE 'file-code' ).
      DATA(lv_node_image) = COND string(
        WHEN lv_is_expanded = abap_true AND ls_node-open_image IS NOT INITIAL
          THEN ls_node-open_image
        ELSE ls_node-node_image ).
      DATA(lv_node_icon) = zcl_gg_host_icons=>icon( iv_name     = lv_node_image
                                                    iv_fallback = lv_icon_name ).
      DATA(lv_selected) = COND string(
        WHEN ls_node-selected = abap_true THEN ' aria-current="true" aria-selected="true"'
        ELSE ' aria-selected="false"' ).
      DATA(lv_hidden) = COND string(
        WHEN lv_visible = abap_false THEN ' hidden' ELSE `` ).
      DATA(lv_indent) = ( lv_depth - 1 ) * 18.
      DATA(lv_tree_toggle) = COND string(
        WHEN lv_has_children = abap_true
          THEN |<button type="button" class="gg-tree-disclosure" data-tree-action="toggle" aria-label="{ COND string( WHEN lv_is_expanded = abap_true THEN 'Collapse' ELSE 'Expand' ) } { zcl_gg_gui_runtime=>escape_html( ls_node-text ) }">{ lv_tree_marker }</button>|
        ELSE '<span class="gg-tree-disclosure" aria-hidden="true"></span>' ).
      result = result && |<tr class="gg-tree-node { cl_gui_control=>state_class( iv_selected = ls_node-selected ) }{ COND string( WHEN node_contains_text( ls_node ) = abap_true THEN ` gg-state-found` ELSE `` ) }" role="treeitem" tabindex="0" aria-level="{ lv_depth }" aria-expanded="{ COND string( WHEN lv_has_children = abap_true THEN COND string( WHEN lv_is_expanded = abap_true THEN 'true' ELSE 'false' ) ELSE `` ) }" data-node-key="{ zcl_gg_gui_runtime=>escape_html( ls_node-node_key ) }" data-parent-key="{ zcl_gg_gui_runtime=>escape_html( ls_node-parent_key ) }" data-has-children="{ COND string( WHEN lv_has_children = abap_true THEN 'true' ELSE 'false' ) }" data-tree-selection="{ COND string( WHEN m_node_selection_mode = cl_gui_column_tree=>node_sel_mode_multiple THEN 'multiple' ELSE 'single' ) }"{ lv_selected }{ lv_hidden }><th scope="row"><span class="gg-tree-indent" style="padding-left:{ lv_indent }px">{ lv_tree_toggle }<span class="gg-tree-node-icon" aria-hidden="true"{ COND string( WHEN lv_node_image IS INITIAL THEN `` ELSE | data-gg-image="{ zcl_gg_gui_runtime=>escape_html( lv_node_image ) }"| ) }>{ lv_node_icon }</span><span class="gg-tree-node-label">{ zcl_gg_gui_runtime=>escape_html( ls_node-text ) }</span></span></th>|.
      LOOP AT mt_fieldcatalog INTO ls_fieldcat.
        IF ls_fieldcat-no_out IS NOT INITIAL OR ls_fieldcat-tech IS NOT INITIAL.
          CONTINUE.
        ENDIF.
        DATA(lv_tree_value) = node_field_text(
          is_node   = ls_node
          fieldname = ls_fieldcat-fieldname ).
        DATA(ls_item_layout) = VALUE lvc_s_layi( ).
        READ TABLE ls_node-item_layout INTO ls_item_layout
          WITH KEY fieldname = ls_fieldcat-fieldname.
        DATA(lv_item_markup) = zcl_gg_gui_runtime=>escape_html( lv_tree_value ).
        IF ls_item_layout-class = 3 OR ls_fieldcat-checkbox = abap_true.
          DATA(lv_checked) = COND string(
            WHEN lv_tree_value = 'X' OR lv_tree_value = '1' THEN ' checked'
            ELSE `` ).
          lv_item_markup = COND string(
            WHEN lv_tree_value IS INITIAL THEN ``
            ELSE |<input type="checkbox" aria-label="{ zcl_gg_gui_runtime=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }"{ lv_checked }>| ).
        ELSEIF ls_item_layout-class = 5.
          lv_item_markup = |<a href="#" class="gg-tree-item-link" data-tree-action="link" data-node-key="{ zcl_gg_gui_runtime=>escape_html( ls_node-node_key ) }" data-item-name="{ zcl_gg_gui_runtime=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }">{ zcl_gg_gui_runtime=>escape_html( lv_tree_value ) }</a>|.
        ELSEIF ls_item_layout-class = 4.
          lv_item_markup = |<button type="button" class="gg-tree-item-button" data-tree-action="button" data-node-key="{ zcl_gg_gui_runtime=>escape_html( ls_node-node_key ) }" data-item-name="{ zcl_gg_gui_runtime=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }">{ zcl_gg_gui_runtime=>escape_html( lv_tree_value ) }</button>|.
        ENDIF.
        DATA(lv_cell_class) = COND string(
          WHEN ls_fieldcat-fieldname = 'QUANTITY' OR ls_fieldcat-fieldname = 'PRICE'
            THEN 'gg-alv-tree-cell gg-alv-tree-cell--number'
          ELSE 'gg-alv-tree-cell' ).
        result = result && |<td class="{ lv_cell_class }" data-fieldname="{ zcl_gg_gui_runtime=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }" data-total="{ COND string( WHEN ls_fieldcat-do_sum = 'X' THEN 'true' ELSE 'false' ) }">{ lv_item_markup }</td>|.
      ENDLOOP.
      result = result && '<td class="gg-alv-tree-filler" aria-hidden="true"></td></tr>'.
    ENDLOOP.
    result = result && '</tbody></table></div></section>'.
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
