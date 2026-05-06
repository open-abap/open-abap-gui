CLASS cl_gui_alv_grid DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        i_parent       TYPE REF TO cl_gui_container
        i_applogparent TYPE REF TO cl_gui_container OPTIONAL
        i_appl_events  TYPE char1 DEFAULT space.

    METHODS set_frontend_layout
      IMPORTING
        is_layout TYPE any.

    METHODS select_text_in_curr_cell.

    METHODS get_selected_columns
      EXPORTING
        et_index_columns TYPE any.

    METHODS set_user_command
      IMPORTING
        i_ucomm TYPE sy-ucomm.

    CLASS-METHODS cell_display
      IMPORTING
        is_data     TYPE any
        i_int_value TYPE any
      EXPORTING
        e_ext_value TYPE any
      CHANGING
        cs_fieldcat TYPE lvc_s_fcat.

    METHODS set_table_for_first_display
      IMPORTING
        i_buffer_active      TYPE any OPTIONAL
        i_bypassing_buffer   TYPE abap_bool OPTIONAL
        i_consistency_check  TYPE abap_bool OPTIONAL
        i_structure_name     TYPE any OPTIONAL
        is_variant           TYPE any OPTIONAL
        i_save               TYPE abap_bool OPTIONAL
        i_default            TYPE abap_bool DEFAULT abap_true
        is_layout            TYPE any OPTIONAL
        is_print             TYPE any OPTIONAL
        it_special_groups    TYPE any OPTIONAL
        it_toolbar_excluding TYPE any OPTIONAL
        it_hyperlink         TYPE any OPTIONAL
        it_alv_graphics      TYPE any OPTIONAL
        it_except_qinfo      TYPE any OPTIONAL
        ir_salv_adapter      TYPE REF TO any OPTIONAL
      CHANGING
        it_outtab            TYPE STANDARD TABLE
        it_fieldcatalog      TYPE any OPTIONAL
        it_sort              TYPE any OPTIONAL
        it_filter            TYPE any OPTIONAL
      EXCEPTIONS
        invalid_parameter_combination
        program_error
        too_many_lines.

    METHODS get_selected_rows
      EXPORTING
        et_index_rows TYPE lvc_t_row
        et_row_no     TYPE lvc_t_roid.

    METHODS refresh_table_display
      IMPORTING
        is_stable      TYPE any OPTIONAL
        i_soft_refresh TYPE abap_bool OPTIONAL
      EXCEPTIONS
        finished.

    METHODS get_filtered_entries
      EXPORTING
        et_filtered_entries TYPE lvc_t_fidx.

    METHODS list_processing_events
      IMPORTING
        i_event_name   TYPE char30
        i_dyndoc_id    TYPE REF TO cl_dd_document OPTIONAL
        ip_subtot_line TYPE REF TO data OPTIONAL
        i_table_index  TYPE i OPTIONAL.

    EVENTS double_click
      EXPORTING
        VALUE(e_row)     TYPE lvc_s_row OPTIONAL
        VALUE(e_column)  TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no) TYPE lvc_s_roid OPTIONAL.

    EVENTS subtotal_text
      EXPORTING
        VALUE(es_subtottxt_info) TYPE lvc_s_stxt OPTIONAL
        VALUE(ep_subtot_line)    TYPE REF TO data OPTIONAL
        VALUE(e_event_data)      TYPE REF TO cl_alv_event_data OPTIONAL.

    EVENTS onf4
      EXPORTING
        VALUE(e_fieldname)   TYPE lvc_fname OPTIONAL
        VALUE(e_fieldvalue)  TYPE lvc_value OPTIONAL
        VALUE(es_row_no)     TYPE lvc_s_roid OPTIONAL
        VALUE(er_event_data) TYPE REF TO cl_alv_event_data OPTIONAL
        VALUE(et_bad_cells)  TYPE lvc_t_modi OPTIONAL
        VALUE(e_display)     TYPE char1 OPTIONAL.

    EVENTS ondropcomplete
      EXPORTING
        VALUE(e_row)         TYPE lvc_s_row OPTIONAL
        VALUE(e_column)      TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no)     TYPE lvc_s_roid OPTIONAL
        VALUE(e_dragdropobj) TYPE REF TO cl_dragdropobject OPTIONAL.

    EVENTS ondrop
      EXPORTING
        VALUE(e_row)         TYPE lvc_s_row OPTIONAL
        VALUE(e_column)      TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no)     TYPE lvc_s_roid OPTIONAL
        VALUE(e_dragdropobj) TYPE REF TO cl_dragdropobject OPTIONAL.

    EVENTS ondrag
      EXPORTING
        VALUE(e_row)         TYPE lvc_s_row OPTIONAL
        VALUE(e_column)      TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no)     TYPE lvc_s_roid OPTIONAL
        VALUE(e_dragdropobj) TYPE REF TO cl_dragdropobject OPTIONAL.

    EVENTS data_changed
      EXPORTING
        VALUE(er_data_changed) TYPE REF TO cl_alv_changed_data_protocol OPTIONAL
        VALUE(e_onf4)          TYPE char1 OPTIONAL
        VALUE(e_onf4_before)   TYPE char1 OPTIONAL
        VALUE(e_onf4_after)    TYPE char1 OPTIONAL
        VALUE(e_ucomm)         TYPE sy-ucomm OPTIONAL.

    EVENTS onf1
      EXPORTING
        VALUE(e_fieldname)   TYPE lvc_fname OPTIONAL
        VALUE(es_row_no)     TYPE lvc_s_roid OPTIONAL
        VALUE(er_event_data) TYPE REF TO cl_alv_event_data OPTIONAL.

    EVENTS before_user_command
      EXPORTING
        VALUE(e_ucomm) TYPE sy-ucomm OPTIONAL.

    EVENTS ondropgetflavor
      EXPORTING
        VALUE(e_row)         TYPE lvc_s_row OPTIONAL
        VALUE(e_column)      TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no)     TYPE lvc_s_roid OPTIONAL
        VALUE(e_dragdropobj) TYPE REF TO cl_dragdropobject OPTIONAL
        VALUE(e_flavors)     TYPE char40 OPTIONAL.

    EVENTS after_user_command
      EXPORTING
        VALUE(e_ucomm)         TYPE sy-ucomm OPTIONAL
        VALUE(e_saved)         TYPE abap_bool OPTIONAL
        VALUE(e_not_processed) TYPE abap_bool OPTIONAL.

    EVENTS user_command
      EXPORTING
        VALUE(e_ucomm) TYPE sy-ucomm OPTIONAL.

    EVENTS hotspot_click
      EXPORTING
        VALUE(e_row_id)    TYPE lvc_s_row OPTIONAL
        VALUE(e_column_id) TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no)   TYPE lvc_s_roid OPTIONAL.

    EVENTS toolbar
      EXPORTING
        VALUE(e_object)      TYPE REF TO cl_alv_event_toolbar_set OPTIONAL
        VALUE(e_interactive) TYPE char1 OPTIONAL.

    EVENTS button_click
      EXPORTING
        VALUE(es_col_id) TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no) TYPE lvc_s_roid OPTIONAL.

    EVENTS data_changed_finished
      EXPORTING
        VALUE(e_modified)    TYPE abap_bool
        VALUE(et_good_cells) TYPE lvc_t_modi OPTIONAL.

    EVENTS menu_button
      EXPORTING
        VALUE(e_object) TYPE REF TO cl_ctmenu OPTIONAL
        VALUE(e_ucomm)  TYPE sy-ucomm OPTIONAL.

    EVENTS context_menu_request
      EXPORTING
        VALUE(e_object) TYPE REF TO cl_ctmenu.

    EVENTS top_of_page
      EXPORTING
        VALUE(e_dyndoc_id) TYPE REF TO cl_dd_document OPTIONAL
        VALUE(table_index) TYPE i OPTIONAL.

    CLASS-METHODS offline
      RETURNING
        VALUE(e_offline) TYPE i.

    METHODS set_sort_criteria
      IMPORTING
        it_sort TYPE lvc_t_sort
      EXCEPTIONS
        no_fieldcatalog_available.

    METHODS save_variant
      IMPORTING
        i_dialog      TYPE abap_bool DEFAULT abap_true
      EXPORTING
        VALUE(e_exit) TYPE abap_bool.

    METHODS set_variant
      IMPORTING
        is_variant TYPE disvariant
        i_save     TYPE abap_bool OPTIONAL.

    METHODS set_ready_for_input
      IMPORTING
        i_ready_for_input TYPE i.

    METHODS set_selected_rows
      IMPORTING
        it_index_rows            TYPE any OPTIONAL
        it_row_no                TYPE any OPTIONAL
        is_keep_other_selections TYPE abap_bool OPTIONAL.

    METHODS set_toolbar_interactive.

    METHODS set_gridtitle
      IMPORTING
        i_gridtitle TYPE lvc_title.

    METHODS set_delta_cells
      IMPORTING
        it_delta_cells  TYPE lvc_t_modi
        i_modified      TYPE abap_bool OPTIONAL
        i_frontend_only TYPE abap_bool OPTIONAL.

    METHODS check_changed_data
      EXPORTING
        e_valid   TYPE abap_bool
      CHANGING
        c_refresh TYPE abap_bool DEFAULT abap_true.

    METHODS get_frontend_layout
      EXPORTING
        es_layout TYPE lvc_s_layo.

    METHODS get_frontend_fieldcatalog
      EXPORTING
        et_fieldcatalog TYPE lvc_t_fcat.

    METHODS set_frontend_fieldcatalog
      IMPORTING
        it_fieldcatalog TYPE lvc_t_fcat.

    METHODS get_current_cell
      EXPORTING
        e_row     TYPE i
        e_value   TYPE c
        e_col     TYPE i
        es_row_id TYPE lvc_s_row
        es_col_id TYPE lvc_s_col
        es_row_no TYPE lvc_s_roid.

    METHODS set_current_cell_via_id
      IMPORTING
        is_row_id    TYPE lvc_s_row OPTIONAL
        is_column_id TYPE lvc_s_col OPTIONAL
        is_row_no    TYPE lvc_s_roid OPTIONAL.

    METHODS get_scroll_info_via_id
      EXPORTING
        es_row_no   TYPE lvc_s_roid
        es_row_info TYPE lvc_s_row
        es_col_info TYPE lvc_s_col.

    METHODS register_edit_event
      IMPORTING
        i_event_id TYPE i
      EXCEPTIONS
        error.

    METHODS set_scroll_info_via_id
      IMPORTING
        is_row_info TYPE lvc_s_row OPTIONAL
        is_col_info TYPE lvc_s_col
        is_row_no   TYPE lvc_s_roid OPTIONAL.

    METHODS get_subtotals
      EXPORTING
        ep_collect00   TYPE REF TO data
        ep_collect01   TYPE REF TO data
        ep_collect02   TYPE REF TO data
        ep_collect03   TYPE REF TO data
        ep_collect04   TYPE REF TO data
        ep_collect05   TYPE REF TO data
        ep_collect06   TYPE REF TO data
        ep_collect07   TYPE REF TO data
        ep_collect08   TYPE REF TO data
        ep_collect09   TYPE REF TO data
        et_grouplevels TYPE lvc_t_grpl.

    METHODS set_selected_columns
      IMPORTING
        it_col_table             TYPE any
        is_keep_other_selections TYPE abap_bool OPTIONAL.

    METHODS register_f4_for_fields
      IMPORTING
        it_f4 TYPE lvc_t_f.

    METHODS get_frontend_print
      EXPORTING
        es_print TYPE lvc_s_prnt.

    METHODS get_sort_criteria
      EXPORTING
        et_sort TYPE lvc_t_sort.

    METHODS get_variant
      EXPORTING
        es_variant TYPE disvariant
        e_save     TYPE char1.

    METHODS set_drop_down_table
      IMPORTING
        it_drop_down       TYPE lvc_t_drop OPTIONAL
        it_drop_down_alias TYPE lvc_t_dral OPTIONAL.

    METHODS get_filter_criteria
      EXPORTING
        et_filter TYPE lvc_t_filt.

    METHODS get_selected_cells
      EXPORTING
        et_cell TYPE lvc_t_cell.

    METHODS register_delayed_event
      IMPORTING
        i_event_id TYPE i.

    METHODS is_ready_for_input
      IMPORTING
        i_row_id               TYPE i OPTIONAL
        is_col_id              TYPE lvc_s_col OPTIONAL
      RETURNING
        VALUE(ready_for_input) TYPE i.

    METHODS set_function_code
      IMPORTING
        has_lvc_format TYPE abap_bool DEFAULT abap_false
      CHANGING
        c_ucomm        TYPE sy-ucomm.

    METHODS set_filter_criteria
      IMPORTING
        it_filter TYPE lvc_t_filt.

    METHODS set_selected_cells
      IMPORTING
        it_cells TYPE lvc_t_cell.

    METHODS set_3d_border
      IMPORTING
        border TYPE i
      EXCEPTIONS
        error.

    METHODS raise_event
      IMPORTING
      i_ucomm         TYPE sy-ucomm OPTIONAL
      i_user_command  TYPE abap_bool OPTIONAL
      i_not_processed TYPE abap_bool OPTIONAL
      PREFERRED PARAMETER i_ucomm.

    CONSTANTS mc_fc_average TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_back_classic TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_abc TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_chain TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_crbatch TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_crweb TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_lineitems TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_master_data TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_more TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_report TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_xint TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_xxl TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_check TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_col_invisible TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_col_optimize TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_count TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_current_variant TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_data_save TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_delete_filter TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_deselect_all TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_detail TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_excl_all TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_expcrdata TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_expcrdesig TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_expcrtempl TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_expmdb TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_extend TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_f4 TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_filter TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_find TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_fix_columns TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_graph TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_help TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_html TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_info TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_load_variant TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_append_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_copy TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_copy_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_cut TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_delete_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_insert_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_move_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_paste TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_paste_new_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_undo TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_maintain_variant TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_maximum TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_minimum TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_pc_file TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_print TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_print_back TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_print_prev TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_refresh TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_reprep TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_save_variant TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_select_all TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_send TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_separator TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_sort TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_sort_asc TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_sort_dsc TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_subtot TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_sum TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_to_office TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_to_rep_tree TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_unfix_columns TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_url_copy_to_clipboard TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_variant_admin TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_view_crystal TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_view_excel TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_view_grid TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_view_lotus TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_views TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_word_processor TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_call_xml_export TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fg_edit TYPE ui_func VALUE 'TODO'.

    CONSTANTS mc_style_disabled TYPE x LENGTH 4 VALUE '00100000'.
    CONSTANTS mc_style_enabled TYPE x LENGTH 4 VALUE '00000000'.
    CONSTANTS mc_style4_link_no TYPE x LENGTH 4 VALUE '00000008'.
    CONSTANTS mc_style_button TYPE x LENGTH 4 VALUE '20000000'.
    CONSTANTS mc_style_f4 TYPE x LENGTH 4 VALUE '02000000'.
    CONSTANTS mc_style_f4_no TYPE x LENGTH 4 VALUE '04000000'.
    CONSTANTS mc_style_hotspot TYPE x LENGTH 4 VALUE '00200000'.
    CONSTANTS mc_style_hotspot_no TYPE x LENGTH 4 VALUE '00400000'.
    CONSTANTS mc_style_no_delete_row TYPE x LENGTH 4 VALUE '10000000'.

    CONSTANTS mc_mb_paste TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_mb_sum TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_mb_subtot TYPE ui_func VALUE 'TODO'.

    CONSTANTS mc_evt_enter TYPE i VALUE 1.
    CONSTANTS mc_evt_modified TYPE i VALUE 2.

    CONSTANTS mc_evt_delayed_change_select TYPE i VALUE 7.
    CONSTANTS mc_fc_auf TYPE ui_func VALUE '&AUF'.
    CONSTANTS mc_fc_find_more TYPE ui_func VALUE '&FIND_MORE'.
    CONSTANTS mc_fg_sort TYPE ui_func VALUE '&FG_SORT'.
    CONSTANTS mc_mb_export TYPE ui_func VALUE '&MB_EXPORT'.
    CONSTANTS mc_mb_filter TYPE ui_func VALUE '&MB_FILTER'.
    CONSTANTS mc_mb_variant TYPE ui_func VALUE '&MB_VARIANT'.
    CONSTANTS mc_mb_view TYPE ui_func VALUE '&MB_VIEW'.

  PROTECTED SECTION.
    DATA mt_outtab TYPE REF TO data.

ENDCLASS.

CLASS cl_gui_alv_grid IMPLEMENTATION.
  METHOD save_variant.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_variant.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD cell_display.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_user_command.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_delta_cells.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD raise_event.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_3d_border.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_cells.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD select_text_in_curr_cell.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_sort_criteria.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_filtered_entries.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_filter_criteria.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_function_code.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD is_ready_for_input.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD register_delayed_event.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_cells.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_filter_criteria.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_drop_down_table.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_variant.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_sort_criteria.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_frontend_print.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD list_processing_events.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD register_f4_for_fields.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_subtotals.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_frontend_fieldcatalog.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_scroll_info_via_id.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD register_edit_event.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_scroll_info_via_id.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_current_cell_via_id.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_current_cell.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_frontend_fieldcatalog.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_frontend_layout.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD check_changed_data.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_gridtitle.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_frontend_layout.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_toolbar_interactive.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_ready_for_input.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_selected_rows.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD offline.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD refresh_table_display.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_table_for_first_display.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_selected_rows.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.