CLASS cl_alv_tree_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS c_hierarchy_column_name TYPE string VALUE '&Hierarchy'.
    CONSTANTS c_virtual_root_node TYPE lvc_nkey VALUE '&VIRTUALROOT'.

    CONSTANTS mc_fc_calculate TYPE ui_func VALUE '&CALC'.
    CONSTANTS mc_fc_current_variant TYPE ui_func VALUE '&COL0'.
    CONSTANTS mc_fc_load_variant TYPE ui_func VALUE '&LOAD'.
    CONSTANTS mc_fc_maintain_variant TYPE ui_func VALUE '&MAINTAIN'.
    CONSTANTS mc_fc_print_back TYPE ui_func VALUE '&PRINT_BACK'.
    CONSTANTS mc_fc_print_back_all TYPE ui_func VALUE '&PRINT_BACK_ALL'.
    CONSTANTS mc_fc_save_variant TYPE ui_func VALUE '&SAVE'.

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
    DATA mt_toolbar_excluding TYPE ui_functions.
    DATA mr_toolbar TYPE REF TO cl_gui_toolbar.
    DATA mt_outtab TYPE REF TO data.
    DATA mt_sort TYPE lvc_t_sort.
    DATA mt_fieldcatalog TYPE lvc_t_fcat.
    DATA mr_column_tree TYPE REF TO cl_gui_column_tree.
    DATA mt_checked_items TYPE lvc_t_chit.
    DATA m_node_selection_mode TYPE i.

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

  PRIVATE SECTION.

ENDCLASS.

CLASS cl_alv_tree_base IMPLEMENTATION.
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