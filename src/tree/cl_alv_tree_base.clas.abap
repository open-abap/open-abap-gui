CLASS cl_alv_tree_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS c_hierarchy_column_name TYPE string VALUE '&Hierarchy'.
    CONSTANTS c_virtual_root_node TYPE lvc_nkey VALUE '&VIRTUALROOT'.
    CONSTANTS c_hierarchy_header_name TYPE lvc_fname VALUE 'HierarchyHeader'.

    CONSTANTS mc_fc_calculate TYPE ui_func VALUE '&CALC'.
    CONSTANTS mc_fc_current_variant TYPE ui_func VALUE '&COL0'.
    CONSTANTS mc_fc_load_variant TYPE ui_func VALUE '&LOAD'.
    CONSTANTS mc_fc_maintain_variant TYPE ui_func VALUE '&MAINTAIN'.
    CONSTANTS mc_fc_print_back TYPE ui_func VALUE '&PRINT_BACK'.
    CONSTANTS mc_fc_print_back_all TYPE ui_func VALUE '&PRINT_BACK_ALL'.
    CONSTANTS mc_fc_save_variant TYPE ui_func VALUE '&SAVE'.
    CONSTANTS mc_fc_help TYPE ui_func VALUE '&HELP'.
    CONSTANTS mc_fc_graphics TYPE ui_func VALUE '&GRAPHCIS'.

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
    DATA mt_toolbar_excluding TYPE ui_functions.

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

  PRIVATE SECTION.

ENDCLASS.

CLASS cl_alv_tree_base IMPLEMENTATION.
  METHOD authority_check.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_column.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_toolbar_buttons.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_filter.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_fieldcatalog.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_first_fieldcatalog.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_report_header.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_model_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD vroot_children_to_queue.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD calculate_subtree.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD apply_filter.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD tree_init.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_node_context_menu.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_hierarchy_help_fields.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD handle_generic_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_item_context_menu.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_children_to_control.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_children_at_front.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD update_checked_items.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_subtree_to_control.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD ensure_node_in_control_int.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD tree_node_has_children.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD tree_get_first_leafe.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD tree_get_parent.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD tree_get_children.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_index_from_node_key.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD frontend_update.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD determine_icon_for_exception.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD change_line.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_node_key_from_index.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_default_drop.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_registered_events.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_toolbar_object.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD column_optimize.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD update_calculations.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_frontend_fieldcatalog.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.