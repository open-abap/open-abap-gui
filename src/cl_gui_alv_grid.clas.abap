CLASS cl_gui_alv_grid DEFINITION PUBLIC INHERITING FROM cl_gui_alv_grid_base.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        i_parent         TYPE REF TO cl_gui_container
        i_applogparent   TYPE REF TO cl_gui_container OPTIONAL
        i_shellstyle     TYPE any OPTIONAL
        i_lifetime       TYPE any OPTIONAL
        i_parentdbg      TYPE any OPTIONAL
        i_graphicsparent TYPE any OPTIONAL
        i_name           TYPE any OPTIONAL
        i_fcat_complete  TYPE any OPTIONAL
        i_appl_events    TYPE char1 DEFAULT space.

    METHODS get_selected_cells_id
      EXPORTING
        et_cells TYPE lvc_t_ceno.

    METHODS set_selected_cells_id
      IMPORTING
        it_cells TYPE lvc_t_ceno.

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
        is_variant           TYPE disvariant OPTIONAL
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
        VALUE(e_flavors)     TYPE cndd_flavors OPTIONAL.

    EVENTS after_user_command
      EXPORTING
        VALUE(e_ucomm)         TYPE sy-ucomm OPTIONAL
        VALUE(e_saved)         TYPE abap_bool OPTIONAL
        VALUE(e_not_processed) TYPE abap_bool OPTIONAL.

* Raised once the selection has settled, after REGISTER_DELAYED_EVENT was
* called with MC_EVT_DELAYED_CHANGE_SELECT. The event carries no parameters.
    EVENTS delayed_changed_sel_callback.

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
        it_f4 TYPE lvc_t_f4.

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

    CONSTANTS mc_fc_average TYPE ui_func VALUE '&AVERAGE'.
    CONSTANTS mc_fc_back_classic TYPE ui_func VALUE '&F03'.
    CONSTANTS mc_fc_call_abc TYPE ui_func VALUE '&ABC'.
    CONSTANTS mc_fc_call_chain TYPE ui_func VALUE '&BEBN'.
    CONSTANTS mc_fc_call_crbatch TYPE ui_func VALUE '&CRBATCH'.
    CONSTANTS mc_fc_call_crweb TYPE ui_func VALUE '&CRWEB'.
    CONSTANTS mc_fc_call_lineitems TYPE ui_func VALUE '&BEB1'.
    CONSTANTS mc_fc_call_master_data TYPE ui_func VALUE '&BEB2'.
    CONSTANTS mc_fc_call_more TYPE ui_func VALUE '&BEB3'.
    CONSTANTS mc_fc_call_report TYPE ui_func VALUE '&BEB9'.
    CONSTANTS mc_fc_call_xint TYPE ui_func VALUE '&XINT'.
    CONSTANTS mc_fc_call_xxl TYPE ui_func VALUE '&XXL'.
    CONSTANTS mc_fc_check TYPE ui_func VALUE '&CHECK'.
    CONSTANTS mc_fc_col_invisible TYPE ui_func VALUE '&COL_INV'.
    CONSTANTS mc_fc_col_optimize TYPE ui_func VALUE '&OPTIMIZE'.
    CONSTANTS mc_fc_count TYPE ui_func VALUE '&COUNT'.
    CONSTANTS mc_fc_current_variant TYPE ui_func VALUE '&COL0'.
    CONSTANTS mc_fc_data_save TYPE ui_func VALUE '&DATA_SAVE'.
    CONSTANTS mc_fc_delete_filter TYPE ui_func VALUE '&DELETE_FILTER'.
    CONSTANTS mc_fc_deselect_all TYPE ui_func VALUE '&SAL'.
    CONSTANTS mc_fc_detail TYPE ui_func VALUE '&DETAIL'.
    CONSTANTS mc_fc_excl_all TYPE ui_func VALUE '&EXCLALLFC'.
    CONSTANTS mc_fc_expcrdata TYPE ui_func VALUE '&CRDATA'.
    CONSTANTS mc_fc_expcrdesig TYPE ui_func VALUE '&CRDESIG'.
    CONSTANTS mc_fc_expcrtempl TYPE ui_func VALUE '&CRTEMPL'.
    CONSTANTS mc_fc_expmdb TYPE ui_func VALUE '&MDB'.
    CONSTANTS mc_fc_extend TYPE ui_func VALUE '&EXT'.
    CONSTANTS mc_fc_f4 TYPE ui_func VALUE '&F4'.
    CONSTANTS mc_fc_filter TYPE ui_func VALUE '&FILTER'.
    CONSTANTS mc_fc_find TYPE ui_func VALUE '&FIND'.
    CONSTANTS mc_fc_fix_columns TYPE ui_func VALUE '&CFI'.
    CONSTANTS mc_fc_graph TYPE ui_func VALUE '&GRAPH'.
    CONSTANTS mc_fc_help TYPE ui_func VALUE '&HELP'.
    CONSTANTS mc_fc_html TYPE ui_func VALUE '&HTML'.
    CONSTANTS mc_fc_info TYPE ui_func VALUE '&INFO'.
    CONSTANTS mc_fc_load_variant TYPE ui_func VALUE '&LOAD'.
    CONSTANTS mc_fc_loc_append_row TYPE ui_func VALUE '&LOCAL&APPEND'.
    CONSTANTS mc_fc_loc_copy TYPE ui_func VALUE '&LOCAL&COPY'.
    CONSTANTS mc_fc_loc_copy_row TYPE ui_func VALUE '&LOCAL&COPY_ROW'.
    CONSTANTS mc_fc_loc_cut TYPE ui_func VALUE '&LOCAL&CUT'.
    CONSTANTS mc_fc_loc_delete_row TYPE ui_func VALUE '&LOCAL&DELETE_ROW'.
    CONSTANTS mc_fc_loc_insert_row TYPE ui_func VALUE '&LOCAL&INSERT_ROW'.
    CONSTANTS mc_fc_loc_move_row TYPE ui_func VALUE '&LOCAL&MOVE_ROW'.
    CONSTANTS mc_fc_loc_paste TYPE ui_func VALUE '&LOCAL&PASTE'.
    CONSTANTS mc_fc_loc_paste_new_row TYPE ui_func VALUE '&LOCAL&PASTE_NEW_ROW'.
    CONSTANTS mc_fc_loc_undo TYPE ui_func VALUE '&LOCAL&UNDO'.
    CONSTANTS mc_fc_maintain_variant TYPE ui_func VALUE '&MAINTAIN'.
    CONSTANTS mc_fc_maximum TYPE ui_func VALUE '&MAXIMUM'.
    CONSTANTS mc_fc_minimum TYPE ui_func VALUE '&MINIMUM'.
    CONSTANTS mc_fc_pc_file TYPE ui_func VALUE '&PC'.
    CONSTANTS mc_fc_print TYPE ui_func VALUE '&PRINT'.
    CONSTANTS mc_fc_print_back TYPE ui_func VALUE '&PRINT_BACK'.
    CONSTANTS mc_fc_print_prev TYPE ui_func VALUE '&PRINT_BACK_PREVIEW'.
    CONSTANTS mc_fc_refresh TYPE ui_func VALUE '&REFRESH'.
    CONSTANTS mc_fc_reprep TYPE ui_func VALUE '&REPREP'.
    CONSTANTS mc_fc_save_variant TYPE ui_func VALUE '&SAVE'.
    CONSTANTS mc_fc_select_all TYPE ui_func VALUE '&ALL'.
    CONSTANTS mc_fc_send TYPE ui_func VALUE '&SEND'.
    CONSTANTS mc_fc_separator TYPE ui_func VALUE '&&SEP'.
    CONSTANTS mc_fc_sort TYPE ui_func VALUE '&SORT'.
    CONSTANTS mc_fc_sort_asc TYPE ui_func VALUE '&SORT_ASC'.
    CONSTANTS mc_fc_sort_dsc TYPE ui_func VALUE '&SORT_DSC'.
    CONSTANTS mc_fc_subtot TYPE ui_func VALUE '&SUBTOT'.
    CONSTANTS mc_fc_sum TYPE ui_func VALUE '&SUMC'.
    CONSTANTS mc_fc_to_office TYPE ui_func VALUE '&ML'.
    CONSTANTS mc_fc_to_rep_tree TYPE ui_func VALUE '&SERP'.
    CONSTANTS mc_fc_unfix_columns TYPE ui_func VALUE '&CDF'.
    CONSTANTS mc_fc_url_copy_to_clipboard TYPE ui_func VALUE '&URL_COPY_TO_CLIPBOARD'.
    CONSTANTS mc_fc_variant_admin TYPE ui_func VALUE '&VARI_ADMIN'.
    CONSTANTS mc_fc_view_crystal TYPE ui_func VALUE '&VCRYSTAL'.
    CONSTANTS mc_fc_view_excel TYPE ui_func VALUE '&VEXCEL'.
    CONSTANTS mc_fc_view_grid TYPE ui_func VALUE '&VGRID'.
    CONSTANTS mc_fc_view_lotus TYPE ui_func VALUE '&VLOTUS'.
    CONSTANTS mc_fc_views TYPE ui_func VALUE '&VIEW'.
    CONSTANTS mc_fc_word_processor TYPE ui_func VALUE '&AQW'.
    CONSTANTS mc_fc_call_xml_export TYPE ui_func VALUE '&XML'.
    CONSTANTS mc_fg_edit TYPE ui_func VALUE '&FG_EDIT'.

    CONSTANTS mc_style_disabled TYPE x LENGTH 4 VALUE '00100000'.
    CONSTANTS mc_style_enabled TYPE x LENGTH 4 VALUE '00080000'.
    CONSTANTS mc_style4_link_no TYPE x LENGTH 4 VALUE '00000008'.
    CONSTANTS mc_style_button TYPE x LENGTH 4 VALUE '20000000'.
    CONSTANTS mc_style_f4 TYPE x LENGTH 4 VALUE '02000000'.
    CONSTANTS mc_style_f4_no TYPE x LENGTH 4 VALUE '04000000'.
    CONSTANTS mc_style_hotspot TYPE x LENGTH 4 VALUE '00200000'.
    CONSTANTS mc_style_hotspot_no TYPE x LENGTH 4 VALUE '00400000'.
    CONSTANTS mc_style_no_delete_row TYPE x LENGTH 4 VALUE '10000000'.

    CONSTANTS mc_mb_paste TYPE ui_func VALUE '&MB_PASTE'.
    CONSTANTS mc_mb_sum TYPE ui_func VALUE '&MB_SUM'.
    CONSTANTS mc_mb_subtot TYPE ui_func VALUE '&MB_SUBTOT'.

    CONSTANTS mc_evt_enter TYPE i VALUE 19.
    CONSTANTS mc_evt_modified TYPE i VALUE 18.

    CONSTANTS mc_evt_delayed_move_curr_cell TYPE i VALUE 5.
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
    DATA mt_toolbar TYPE ttb_button.
    DATA m_batch_mode TYPE sy-batch.
    DATA m_display_protocol TYPE abap_bool.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_html_cell,
             fieldname       TYPE lvc_fname,
             text            TYPE string,
             type_class      TYPE string,
             editable        TYPE abap_bool,
             checkbox        TYPE abap_bool,
             icon            TYPE abap_bool,
             symbol          TYPE abap_bool,
             exception_light TYPE abap_bool,
             emphasize       TYPE string,
             color_code      TYPE string,
             color_style     TYPE string,
             style_button    TYPE abap_bool,
             style_disabled  TYPE abap_bool,
             f4              TYPE abap_bool,
             dropdown        TYPE i,
             total           TYPE abap_bool,
             subtotal        TYPE abap_bool,
             hotspot         TYPE abap_bool,
           END OF ty_html_cell.
    TYPES ty_html_cells TYPE STANDARD TABLE OF ty_html_cell WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_html_row,
             index       TYPE i,
             color_code  TYPE string,
             color_style TYPE string,
             cells       TYPE ty_html_cells,
           END OF ty_html_row.
    TYPES ty_html_rows TYPE STANDARD TABLE OF ty_html_row WITH DEFAULT KEY.
    DATA mt_fieldcatalog TYPE lvc_t_fcat.
    DATA mt_html_rows TYPE ty_html_rows.
    DATA mt_source_rows TYPE ty_html_rows.
    DATA mt_selected_rows TYPE lvc_t_row.
    DATA mt_selected_cells_id TYPE lvc_t_ceno.
    DATA mt_selected_cells TYPE lvc_t_cell.
    DATA mr_selected_columns TYPE REF TO data.
    DATA mt_filtered_entries TYPE lvc_t_fidx.
    DATA mt_sort TYPE lvc_t_sort.
    DATA mt_filter TYPE lvc_t_filt.
    DATA mt_delta_cells TYPE lvc_t_modi.
    DATA mt_drop_down TYPE lvc_t_drop.
    DATA mt_registered_events TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA ms_layout TYPE lvc_s_layo.
    DATA ms_print TYPE lvc_s_prnt.
    DATA ms_variant TYPE disvariant.
    DATA mv_variant_save TYPE c LENGTH 1.
    DATA ms_current_row TYPE lvc_s_row.
    DATA ms_current_col TYPE lvc_s_col.
    DATA ms_current_row_no TYPE lvc_s_roid.
    DATA mv_current_row_index TYPE i.
    DATA mv_current_col_index TYPE i.
    DATA mv_current_value TYPE string.
    DATA ms_scroll_row TYPE lvc_s_row.
    DATA ms_scroll_col TYPE lvc_s_col.
    DATA ms_scroll_row_no TYPE lvc_s_roid.
    DATA mv_ready_for_input TYPE i.
    DATA mv_gridtitle TYPE lvc_title.

    METHODS render_model
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_cell
      IMPORTING
        is_row        TYPE ty_html_row
        is_cell       TYPE ty_html_cell
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_cell_content
      IMPORTING
        iv_row_index  TYPE i
        is_cell       TYPE ty_html_cell
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_aggregate_row
      IMPORTING
        it_rows           TYPE ty_html_rows
        iv_subtotal_field TYPE lvc_fname OPTIONAL
        iv_subtotal_value TYPE string OPTIONAL
      RETURNING
        VALUE(result)     TYPE string.

    "! Turns one output field of one row into the cell the renderer reads. The
    "! field catalogue decides how the value is formatted and which of the cell
    "! flags are set; IV_VALUE is the raw value as it was read from the row.
    METHODS build_cell
      IMPORTING
        is_fieldcat   TYPE lvc_s_fcat
        iv_value      TYPE string
      RETURNING
        VALUE(result) TYPE ty_html_cell.

    METHODS apply_row_display
      IMPORTING
        is_source_row TYPE any
      CHANGING
        cs_row        TYPE ty_html_row.

    METHODS apply_row_colors
      IMPORTING
        is_source_row TYPE any
      CHANGING
        cs_row        TYPE ty_html_row.

    METHODS apply_cell_color
      IMPORTING
        is_color_row TYPE any
      CHANGING
        ct_cells     TYPE ty_html_cells.

    METHODS apply_row_styles
      IMPORTING
        is_source_row TYPE any
      CHANGING
        cs_row        TYPE ty_html_row.

    METHODS apply_cell_style
      IMPORTING
        is_style_row TYPE any
      CHANGING
        ct_cells     TYPE ty_html_cells.

    METHODS lvc_color_style
      IMPORTING
        iv_color      TYPE i
        iv_intensity  TYPE i
        iv_inverse    TYPE i
      RETURNING
        VALUE(result) TYPE string.

    METHODS color_code_style
      IMPORTING
        iv_code       TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS alv_icon_html
      IMPORTING
        iv_code       TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS alv_light_html
      IMPORTING
        iv_value      TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS alv_symbol_html
      IMPORTING
        iv_value      TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS apply_criteria.

    METHODS row_matches
      IMPORTING
        is_row        TYPE ty_html_row
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS row_before
      IMPORTING
        is_left       TYPE ty_html_row
        is_right      TYPE ty_html_row
      RETURNING
        VALUE(result) TYPE abap_bool.
    DATA mt_f4 TYPE lvc_t_f4.
    DATA m_cl_variant TYPE REF TO cl_alv_variant.
    DATA mt_hyperlinks TYPE lvc_t_hype.
    DATA m_init_toolbar TYPE c LENGTH 1.

ENDCLASS.

CLASS cl_gui_alv_grid IMPLEMENTATION.
  METHOD set_selected_cells_id.
    mt_selected_cells_id = it_cells.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD get_selected_cells_id.
    et_cells = mt_selected_cells_id.
  ENDMETHOD.

  METHOD save_variant.
    e_exit = abap_false.
    cl_gui_control=>set_payload(
      control = me
      payload = |ALV variant is report-local; interactive save must be handled by the host| ).
  ENDMETHOD.

  METHOD set_variant.
    ms_variant = is_variant.
    IF i_save IS SUPPLIED.
      mv_variant_save = COND #( WHEN i_save = abap_true THEN 'A' ELSE ' ' ).
    ENDIF.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD cell_display.
    e_ext_value = i_int_value.
    IF cs_fieldcat-inttype IS INITIAL.
      cs_fieldcat-inttype = 'C'.
    ENDIF.
  ENDMETHOD.

  METHOD set_user_command.
    raise_event(
      i_ucomm        = i_ucomm
      i_user_command = abap_true ).
  ENDMETHOD.

  METHOD set_delta_cells.
    mt_delta_cells = it_delta_cells.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD raise_event.
    IF i_user_command = abap_true.
      RAISE EVENT before_user_command EXPORTING e_ucomm = i_ucomm.
      RAISE EVENT user_command EXPORTING e_ucomm = i_ucomm.
      RAISE EVENT after_user_command
        EXPORTING
          e_ucomm         = i_ucomm
          e_not_processed = i_not_processed.
    ENDIF.
  ENDMETHOD.

  METHOD set_3d_border.
    RETURN.
  ENDMETHOD.

  METHOD set_selected_cells.
    mt_selected_cells = it_cells.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD get_selected_columns.
    IF mr_selected_columns IS BOUND.
      et_index_columns = mr_selected_columns->*.
    ELSE.
      CLEAR et_index_columns.
    ENDIF.
  ENDMETHOD.

  METHOD select_text_in_curr_cell.
    cl_gui_control=>set_payload(
      control = me
      payload = |Current cell text selected; row={ ms_current_row-index } column={ ms_current_col-fieldname }| ).
  ENDMETHOD.

  METHOD set_selected_columns.
    IF is_keep_other_selections = abap_false.
      CLEAR mr_selected_columns.
    ENDIF.
    GET REFERENCE OF it_col_table INTO mr_selected_columns.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD set_sort_criteria.
    mt_sort = it_sort.
    SORT mt_sort BY spos.
    apply_criteria( ).
    refresh_table_display( ).
  ENDMETHOD.

  METHOD get_filtered_entries.
    et_filtered_entries = mt_filtered_entries.
  ENDMETHOD.

  METHOD set_filter_criteria.
    mt_filter = it_filter.
    apply_criteria( ).
    refresh_table_display( ).
  ENDMETHOD.

  METHOD set_function_code.
    IF has_lvc_format = abap_true AND c_ucomm IS INITIAL.
      c_ucomm = '&REFRESH'.
    ENDIF.
  ENDMETHOD.

  METHOD is_ready_for_input.
    ready_for_input = mv_ready_for_input.
    IF ready_for_input IS INITIAL.
      ready_for_input = COND #( WHEN mv_enabled = abap_true THEN 1 ELSE 0 ).
    ENDIF.
  ENDMETHOD.

  METHOD register_delayed_event.
    IF NOT line_exists( mt_registered_events[ table_line = i_event_id ] ).
      APPEND i_event_id TO mt_registered_events.
    ENDIF.
  ENDMETHOD.

  METHOD get_selected_cells.
    et_cell = mt_selected_cells.
  ENDMETHOD.

  METHOD get_filter_criteria.
    et_filter = mt_filter.
  ENDMETHOD.

  METHOD set_drop_down_table.
    mt_drop_down = it_drop_down.
    cl_gui_control=>set_payload(
      control = me
      payload = |ALV dropdown entries={ lines( mt_drop_down ) }| ).
  ENDMETHOD.

  METHOD get_variant.
    es_variant = ms_variant.
    e_save = mv_variant_save.
  ENDMETHOD.

  METHOD get_sort_criteria.
    et_sort = mt_sort.
  ENDMETHOD.

  METHOD get_frontend_print.
    es_print = ms_print.
  ENDMETHOD.

  METHOD list_processing_events.
    IF to_upper( i_event_name ) = 'TOP_OF_PAGE'.
      RAISE EVENT top_of_page
        EXPORTING
          e_dyndoc_id = i_dyndoc_id
          table_index = i_table_index.
    ENDIF.
  ENDMETHOD.

  METHOD register_f4_for_fields.
    mt_f4 = it_f4.
  ENDMETHOD.

  METHOD get_subtotals.
    CLEAR: ep_collect00, ep_collect01, ep_collect02, ep_collect03,
      ep_collect04, ep_collect05, ep_collect06, ep_collect07,
      ep_collect08, ep_collect09, et_grouplevels.
  ENDMETHOD.

  METHOD set_frontend_fieldcatalog.
    mt_fieldcatalog = it_fieldcatalog.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD set_scroll_info_via_id.
    IF is_row_info IS SUPPLIED.
      ms_scroll_row = is_row_info.
    ENDIF.
    ms_scroll_col = is_col_info.
    IF is_row_no IS SUPPLIED.
      ms_scroll_row_no = is_row_no.
    ENDIF.
  ENDMETHOD.

  METHOD register_edit_event.
    IF NOT line_exists( mt_registered_events[ table_line = i_event_id ] ).
      APPEND i_event_id TO mt_registered_events.
    ENDIF.
  ENDMETHOD.

  METHOD get_scroll_info_via_id.
    es_row_no = ms_scroll_row_no.
    es_row_info = ms_scroll_row.
    es_col_info = ms_scroll_col.
  ENDMETHOD.

  METHOD set_current_cell_via_id.
    IF is_row_id IS SUPPLIED.
      ms_current_row = is_row_id.
    ENDIF.
    IF is_column_id IS SUPPLIED.
      ms_current_col = is_column_id.
    ENDIF.
    IF is_row_no IS SUPPLIED.
      ms_current_row_no = is_row_no.
    ENDIF.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD get_current_cell.
    e_row = mv_current_row_index.
    e_value = mv_current_value.
    e_col = mv_current_col_index.
    es_row_id = ms_current_row.
    es_col_id = ms_current_col.
    es_row_no = ms_current_row_no.
  ENDMETHOD.

  METHOD get_frontend_fieldcatalog.
    et_fieldcatalog = mt_fieldcatalog.
  ENDMETHOD.

  METHOD get_frontend_layout.
    es_layout = ms_layout.
  ENDMETHOD.

  METHOD check_changed_data.
    e_valid = abap_true.
    c_refresh = abap_false.
  ENDMETHOD.

  METHOD set_gridtitle.
    mv_gridtitle = i_gridtitle.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = i_parent
      kind    = 'ALV_GRID' ).
    mv_toolbar_visible = abap_true.
    i_parent->add_child( me ).
  ENDMETHOD.

  METHOD set_frontend_layout.
    ms_layout = is_layout.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD set_toolbar_interactive.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD set_ready_for_input.
    mv_ready_for_input = i_ready_for_input.
    set_enable( COND #( WHEN i_ready_for_input = 0 THEN space ELSE 'X' ) ).
    refresh_table_display( ).
  ENDMETHOD.

  METHOD set_selected_rows.
    CLEAR mt_selected_rows.
    IF it_row_no IS SUPPLIED.
      mt_selected_rows = it_row_no.
    ELSEIF it_index_rows IS SUPPLIED.
      mt_selected_rows = it_index_rows.
    ENDIF.
    refresh_table_display( ).
  ENDMETHOD.

  METHOD offline.
    e_offline = 0.
  ENDMETHOD.

  METHOD refresh_table_display.
    cl_gui_control=>set_html(
      control = me
      html    = render_model( ) ).
  ENDMETHOD.

  METHOD row_matches.
    result = abap_true.
    LOOP AT mt_filter INTO DATA(ls_filter).
      READ TABLE is_row-cells INTO DATA(ls_cell)
        WITH KEY fieldname = ls_filter-fieldname.
      IF sy-subrc <> 0.
        result = abap_false.
        RETURN.
      ENDIF.
      DATA(lv_low) = CONV string( ls_filter-low ).
      DATA(lv_high) = CONV string( ls_filter-high ).
      SHIFT lv_low RIGHT DELETING TRAILING space.
      SHIFT lv_low LEFT DELETING LEADING space.
      SHIFT lv_high RIGHT DELETING TRAILING space.
      SHIFT lv_high LEFT DELETING LEADING space.
      DATA(lv_match) = cl_gui_control=>compare_option(
        iv_value         = ls_cell-text
        iv_option        = CONV string( ls_filter-option )
        iv_low           = lv_low
        iv_high          = lv_high
        iv_sign          = CONV string( ls_filter-sign )
        iv_unknown_as_eq = abap_true ).
      IF lv_match = abap_false.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD row_before.
    LOOP AT mt_sort INTO DATA(ls_sort).
      READ TABLE is_left-cells INTO DATA(ls_left)
        WITH KEY fieldname = ls_sort-fieldname.
      READ TABLE is_right-cells INTO DATA(ls_right)
        WITH KEY fieldname = ls_sort-fieldname.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF ls_left-text = ls_right-text.
        CONTINUE.
      ENDIF.
      IF ls_sort-down = 'X'.
        result = xsdbool( ls_left-text > ls_right-text ).
      ELSE.
        result = xsdbool( ls_left-text < ls_right-text ).
      ENDIF.
      RETURN.
    ENDLOOP.
    result = abap_false.
  ENDMETHOD.

  METHOD apply_criteria.
    DATA lv_index TYPE i.
    DATA lv_count TYPE i.
    DATA ls_left TYPE ty_html_row.
    DATA ls_right TYPE ty_html_row.

    IF mt_source_rows IS INITIAL.
      RETURN.
    ENDIF.
    CLEAR: mt_html_rows, mt_filtered_entries.
    LOOP AT mt_source_rows INTO DATA(ls_source).
      IF row_matches( ls_source ) = abap_true.
        APPEND ls_source TO mt_html_rows.
      ELSE.
        APPEND ls_source-index TO mt_filtered_entries.
      ENDIF.
    ENDLOOP.
    lv_count = lines( mt_html_rows ).
    IF lv_count < 2 OR mt_sort IS INITIAL.
      RETURN.
    ENDIF.
    DO lv_count TIMES.
      LOOP AT mt_html_rows INTO ls_left.
        lv_index = sy-tabix.
        IF lv_index >= lv_count.
          CONTINUE.
        ENDIF.
        READ TABLE mt_html_rows INTO ls_right INDEX lv_index + 1.
        DATA(lv_swap) = row_before(
          is_left  = ls_right
          is_right = ls_left ).
        IF lv_swap = abap_true.
          MODIFY mt_html_rows FROM ls_right INDEX lv_index.
          MODIFY mt_html_rows FROM ls_left INDEX lv_index + 1.
        ENDIF.
      ENDLOOP.
    ENDDO.
  ENDMETHOD.

  METHOD build_cell.
    result = VALUE #(
      fieldname       = is_fieldcat-fieldname
      text            = cl_gui_control=>format_external_value(
                     iv_value = iv_value
                     iv_type  = CONV string( is_fieldcat-inttype ) )
      type_class      = COND string(
        WHEN is_fieldcat-inttype = 'I'
          OR is_fieldcat-inttype = 'P'
          OR is_fieldcat-inttype = 'N'
          OR is_fieldcat-inttype = 'F'
          THEN `gg-type-number`
        WHEN is_fieldcat-inttype = 'D' THEN `gg-type-date`
        WHEN is_fieldcat-inttype = 'T' THEN `gg-type-time`
        ELSE `gg-type-text` )
      editable        = xsdbool( is_fieldcat-edit = 'X' )
      checkbox        = xsdbool( is_fieldcat-checkbox = 'X' )
      icon            = xsdbool( is_fieldcat-icon = 'X' )
      symbol          = xsdbool( is_fieldcat-symbol = 'X' )
      exception_light = xsdbool( ms_layout-excp_led = 'X'
                                AND ms_layout-excp_fname = is_fieldcat-fieldname )
      emphasize       = CONV string( is_fieldcat-emphasize )
      f4              = xsdbool( is_fieldcat-f4availabl = 'X' )
      dropdown        = is_fieldcat-drdn_hndl
      total           = xsdbool( is_fieldcat-do_sum = 'X' )
      subtotal        = xsdbool( line_exists( mt_sort[ fieldname = is_fieldcat-fieldname subtot = 'X' ] ) )
      hotspot         = xsdbool( is_fieldcat-hotspot = 'X' ) ).
  ENDMETHOD.

  METHOD apply_row_display.
    apply_row_colors(
      EXPORTING is_source_row = is_source_row
      CHANGING  cs_row        = cs_row ).
    apply_row_styles(
      EXPORTING is_source_row = is_source_row
      CHANGING  cs_row        = cs_row ).
  ENDMETHOD.

  METHOD apply_row_colors.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <color_rows> TYPE ANY TABLE.
    FIELD-SYMBOLS <color_row> TYPE any.

    IF ms_layout-info_fname IS NOT INITIAL.
      ASSIGN COMPONENT ms_layout-info_fname OF STRUCTURE is_source_row TO <value>.
      IF sy-subrc = 0.
        cs_row-color_code = CONV string( <value> ).
        cs_row-color_style = color_code_style( cs_row-color_code ).
      ENDIF.
    ENDIF.
    IF ms_layout-ctab_fname IS INITIAL.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT ms_layout-ctab_fname OF STRUCTURE is_source_row TO <color_rows>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT <color_rows> ASSIGNING <color_row>.
      apply_cell_color(
        EXPORTING is_color_row = <color_row>
        CHANGING  ct_cells     = cs_row-cells ).
    ENDLOOP.
  ENDMETHOD.

  METHOD apply_cell_color.
    FIELD-SYMBOLS <fieldname> TYPE any.
    FIELD-SYMBOLS <color> TYPE any.
    FIELD-SYMBOLS <color_value> TYPE any.
    FIELD-SYMBOLS <cell> TYPE ty_html_cell.
    DATA lv_color TYPE i.
    DATA lv_intensity TYPE i.
    DATA lv_inverse TYPE i.

    ASSIGN COMPONENT 'FNAME' OF STRUCTURE is_color_row TO <fieldname>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    READ TABLE ct_cells ASSIGNING <cell> WITH KEY fieldname = <fieldname>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT 'COLOR' OF STRUCTURE is_color_row TO <color>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT 'COL' OF STRUCTURE <color> TO <color_value>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_color = <color_value>.
    ASSIGN COMPONENT 'INT' OF STRUCTURE <color> TO <color_value>.
    IF sy-subrc = 0.
      lv_intensity = <color_value>.
    ENDIF.
    ASSIGN COMPONENT 'INV' OF STRUCTURE <color> TO <color_value>.
    IF sy-subrc = 0.
      lv_inverse = <color_value>.
    ENDIF.
    <cell>-color_code = |{ lv_color }{ lv_intensity }{ lv_inverse }|.
    <cell>-color_style = lvc_color_style(
      iv_color     = lv_color
      iv_intensity = lv_intensity
      iv_inverse   = lv_inverse ).
  ENDMETHOD.

  METHOD apply_row_styles.
    FIELD-SYMBOLS <style_rows> TYPE ANY TABLE.
    FIELD-SYMBOLS <style_row> TYPE any.

    IF ms_layout-stylefname IS INITIAL.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT ms_layout-stylefname OF STRUCTURE is_source_row TO <style_rows>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT <style_rows> ASSIGNING <style_row>.
      apply_cell_style(
        EXPORTING is_style_row = <style_row>
        CHANGING  ct_cells     = cs_row-cells ).
    ENDLOOP.
  ENDMETHOD.

  METHOD apply_cell_style.
    FIELD-SYMBOLS <fieldname> TYPE any.
    FIELD-SYMBOLS <style_value> TYPE any.
    FIELD-SYMBOLS <cell> TYPE ty_html_cell.
    DATA lv_style TYPE x LENGTH 4.

    ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE is_style_row TO <fieldname>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    READ TABLE ct_cells ASSIGNING <cell> WITH KEY fieldname = <fieldname>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT 'STYLE' OF STRUCTURE is_style_row TO <style_value>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_style = <style_value>.
    CASE lv_style.
      WHEN mc_style_button.
        <cell>-style_button = abap_true.
      WHEN mc_style_disabled.
        <cell>-style_disabled = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD lvc_color_style.
    DATA lv_background TYPE string.
    DATA lv_foreground TYPE string.

    CASE iv_color.
      WHEN 0.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#edf5fb' ELSE '#d2dce5' ).
        lv_foreground = '#263b4d'.
      WHEN 1.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#d9e8f5' ELSE '#aac8de' ).
        lv_foreground = '#17415f'.
      WHEN 2.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#e6ecf1' ELSE '#cbd5de' ).
        lv_foreground = '#33414c'.
      WHEN 3.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#fff3c4' ELSE '#f2dc86' ).
        lv_foreground = '#634d00'.
      WHEN 4.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#ddf1f2' ELSE '#a8dadd' ).
        lv_foreground = '#14545a'.
      WHEN 5.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#e2f3e5' ELSE '#b9e0c1' ).
        lv_foreground = '#1d6136'.
      WHEN 6.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#fbe1de' ELSE '#f0b9b3' ).
        lv_foreground = '#8d231b'.
      WHEN 7.
        lv_background = COND string( WHEN iv_intensity = 0 THEN '#fbead6' ELSE '#f0d0a7' ).
        lv_foreground = '#73410a'.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
    IF iv_inverse <> 0.
      result = |color:{ lv_foreground }|.
    ELSE.
      result = |background-color:{ lv_background };color:{ lv_foreground }|.
    ENDIF.
  ENDMETHOD.

  METHOD color_code_style.
    DATA lv_code TYPE string.

    lv_code = iv_code.
    SHIFT lv_code RIGHT DELETING TRAILING space.
    IF strlen( lv_code ) < 4 OR lv_code+0(1) <> 'C'
        OR lv_code+1(1) CN `01234567`
        OR lv_code+2(1) CN `01`
        OR lv_code+3(1) CN `01`.
      RETURN.
    ENDIF.
    result = lvc_color_style(
      iv_color     = CONV i( lv_code+1(1) )
      iv_intensity = CONV i( lv_code+2(1) )
      iv_inverse   = CONV i( lv_code+3(1) ) ).
  ENDMETHOD.

  METHOD alv_icon_html.
    DATA lv_icon_name TYPE string.
    DATA lv_label TYPE string.
    DATA lv_color TYPE string.

    CASE iv_code.
      WHEN '@01@'.
        lv_icon_name = 'success'.
        lv_label = 'Active'.
        lv_color = '#218342'.
      WHEN '@02@'.
        lv_icon_name = 'error'.
        lv_label = 'Inactive'.
        lv_color = '#b3261e'.
      WHEN OTHERS.
        result = |<span class="gg-alv-icon" role="img" aria-label="ALV icon">{ cl_gui_control=>escape_html( iv_code ) }</span>|.
        RETURN.
    ENDCASE.
    result = |<span class="gg-alv-icon" role="img" aria-label="{ lv_label }" style="color:{ lv_color };display:inline-flex;align-items:center;font-size:16px">{ zcl_gg_host_icons=>icon( iv_name = lv_icon_name ) }</span>|.
  ENDMETHOD.

  METHOD alv_light_html.
    DATA lv_icon_name TYPE string.
    DATA lv_label TYPE string.
    DATA lv_color TYPE string.

    CASE iv_value.
      WHEN '1'.
        lv_icon_name = 'error'.
        lv_label = 'Red traffic light'.
        lv_color = '#b3261e'.
      WHEN '2'.
        lv_icon_name = 'warning'.
        lv_label = 'Yellow traffic light'.
        lv_color = '#a56300'.
      WHEN '3'.
        lv_icon_name = 'success'.
        lv_label = 'Green traffic light'.
        lv_color = '#218342'.
      WHEN OTHERS.
        result = cl_gui_control=>escape_html( iv_value ).
        RETURN.
    ENDCASE.
    result = |<span class="gg-alv-light" role="img" aria-label="{ lv_label }" data-light="{ iv_value }" style="color:{ lv_color };display:inline-flex;align-items:center;font-size:16px">{ zcl_gg_host_icons=>icon( iv_name = lv_icon_name ) }</span>|.
  ENDMETHOD.

  METHOD alv_symbol_html.
    CASE iv_value.
      WHEN '+'.
        result = '<span class="gg-alv-symbol gg-alv-symbol-positive" role="img" aria-label="Positive symbol">&#x25C6;</span>'.
      WHEN '-'.
        result = '<span class="gg-alv-symbol gg-alv-symbol-negative" role="img" aria-label="Negative symbol">&#x25AF;</span>'.
      WHEN OTHERS.
        result = |<span class="gg-alv-symbol" role="img" aria-label="{ cl_gui_control=>escape_html( iv_value ) }">{ cl_gui_control=>escape_html( iv_value ) }</span>|.
    ENDCASE.
  ENDMETHOD.

  METHOD set_table_for_first_display.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.
    DATA ls_row TYPE ty_html_row.
    DATA ls_cell TYPE ty_html_cell.
    DATA ls_fieldcat TYPE lvc_s_fcat.
    DATA lv_has_component TYPE abap_bool.

    CLEAR mt_html_rows.
    CLEAR mt_source_rows.
    CLEAR mt_fieldcatalog.
    IF is_layout IS SUPPLIED.
      ms_layout = is_layout.
    ENDIF.
    IF it_fieldcatalog IS SUPPLIED.
      mt_fieldcatalog = it_fieldcatalog.
    ENDIF.
    IF it_sort IS SUPPLIED.
      mt_sort = it_sort.
      SORT mt_sort BY spos.
    ENDIF.
    IF it_filter IS SUPPLIED.
      mt_filter = it_filter.
    ENDIF.
    GET REFERENCE OF it_outtab INTO mt_outtab.
    LOOP AT it_outtab ASSIGNING <row>.
      ls_row = VALUE #( index = sy-tabix ).
      IF mt_fieldcatalog IS INITIAL.
        APPEND VALUE #( fieldname = `VALUE`
                        text      = |{ <row> }| ) TO ls_row-cells.
      ELSE.
        lv_has_component = abap_false.
        LOOP AT mt_fieldcatalog INTO ls_fieldcat.
          IF ls_fieldcat-no_out IS INITIAL AND ls_fieldcat-tech IS INITIAL.
            ASSIGN COMPONENT ls_fieldcat-fieldname OF STRUCTURE <row> TO <component>.
            IF sy-subrc = 0.
              ls_cell = build_cell( is_fieldcat = ls_fieldcat
                                    iv_value    = |{ <component> }| ).
              APPEND ls_cell TO ls_row-cells.
              lv_has_component = abap_true.
            ENDIF.
          ENDIF.
        ENDLOOP.
        IF lv_has_component = abap_false.
* No component of the row matched the catalogue, so the row is rendered as a
* single cell described by the first field.
          READ TABLE mt_fieldcatalog INTO ls_fieldcat INDEX 1.
          IF sy-subrc = 0.
            ls_cell = build_cell( is_fieldcat = ls_fieldcat
                                  iv_value    = |{ <row> }| ).
            APPEND ls_cell TO ls_row-cells.
          ENDIF.
        ENDIF.
      ENDIF.
      apply_row_display(
        EXPORTING is_source_row = <row>
        CHANGING  cs_row        = ls_row ).
      APPEND ls_row TO mt_html_rows.
    ENDLOOP.
    mt_source_rows = mt_html_rows.
    apply_criteria( ).
    cl_gui_control=>set_html(
      control = me
      html    = render_model( ) ).
  ENDMETHOD.

  METHOD render_cell.
    DATA(lv_cell_state_class) = cl_gui_control=>state_class(
      iv_total    = is_cell-total
      iv_subtotal = is_cell-subtotal
      iv_hotspot  = is_cell-hotspot
      iv_readonly = xsdbool( is_cell-editable = abap_false ) ).
    DATA(lv_cell_color_style) = is_cell-color_style.
    DATA(lv_cell_color_code) = is_cell-color_code.
    IF lv_cell_color_style IS INITIAL AND is_cell-emphasize IS NOT INITIAL.
      lv_cell_color_style = color_code_style( is_cell-emphasize ).
      lv_cell_color_code = is_cell-emphasize.
    ENDIF.
    IF lv_cell_color_style IS INITIAL.
      lv_cell_color_style = is_row-color_style.
      lv_cell_color_code = is_row-color_code.
    ENDIF.
    DATA(lv_disabled_class) = COND string(
      WHEN is_cell-style_disabled = abap_true THEN ` gg-state-disabled` ELSE `` ).
    DATA(lv_lvc_style) = COND string(
      WHEN is_cell-style_button = abap_true THEN `button`
      WHEN is_cell-style_disabled = abap_true THEN `disabled`
      ELSE `standard` ).
    DATA(lv_cell_content) = render_cell_content(
      iv_row_index = is_row-index
      is_cell      = is_cell ).
    result = |<td class="gg-grid-cell { lv_cell_state_class } { is_cell-type_class }{ lv_disabled_class }" data-subtotal="{ COND string( WHEN is_cell-subtotal = abap_true THEN 'true' ELSE 'false' ) }" data-emphasize="{ cl_gui_control=>escape_html( is_cell-emphasize ) }" data-lvc-color="{ cl_gui_control=>escape_html( lv_cell_color_code ) }" data-lvc-style="{ lv_lvc_style }" style="{ lv_cell_color_style }"{ COND string( WHEN is_cell-f4 = abap_true THEN ` data-f4="true"` ELSE `` ) } data-fieldname="{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) }">{ lv_cell_content }</td>|.
  ENDMETHOD.

  METHOD render_cell_content.
    IF is_cell-dropdown > 0.
      result = |<select name="gg-alv-cell-{ iv_row_index }-{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) }" aria-label="{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) } row { iv_row_index }"{ COND string( WHEN is_cell-style_disabled = abap_true THEN ` disabled aria-disabled="true"` ELSE `` ) }>|.
      LOOP AT mt_drop_down INTO DATA(ls_drop) WHERE handle = is_cell-dropdown.
        result = result && |<option value="{ cl_gui_control=>escape_html( CONV string( ls_drop-value ) ) }"{ COND string( WHEN ls_drop-value = is_cell-text THEN ` selected` ELSE `` ) }>{ cl_gui_control=>escape_html( CONV string( ls_drop-value ) ) }</option>|.
      ENDLOOP.
      result = result && `</select>`.
    ELSEIF is_cell-checkbox = abap_true.
      result = |<input type="checkbox" name="gg-alv-cell-{ iv_row_index }-{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) }" aria-label="{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) } row { iv_row_index }"{ COND string( WHEN is_cell-text = 'X' OR is_cell-text = '1' THEN ` checked` ELSE `` ) }{ COND string( WHEN is_cell-style_disabled = abap_true THEN ` disabled aria-disabled="true"` ELSE `` ) }>|.
    ELSEIF is_cell-editable = abap_true.
      result = |<input type="text" name="gg-alv-cell-{ iv_row_index }-{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) }" value="{ cl_gui_control=>escape_html( is_cell-text ) }" aria-label="{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) } row { iv_row_index }"{ COND string( WHEN is_cell-style_disabled = abap_true THEN ` disabled aria-disabled="true"` ELSE `` ) }>|.
    ELSEIF is_cell-style_button = abap_true.
      result = |<button type="button" class="gg-alv-style-button" aria-label="{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) } row { iv_row_index }" style="background:#fff2a8;border:1px solid #bca848;padding:2px 10px;color:#25384a;border-radius:2px">{ cl_gui_control=>escape_html( is_cell-text ) }</button>|.
    ELSEIF is_cell-hotspot = abap_true.
      result = |<button type="submit" name="gg_action" value="COMMAND:ALV-HOTSPOT-{ iv_row_index }-{ cl_gui_control=>escape_html( CONV string( is_cell-fieldname ) ) }">{ cl_gui_control=>escape_html( is_cell-text ) }</button>|.
    ELSEIF is_cell-exception_light = abap_true.
      result = alv_light_html( is_cell-text ).
    ELSEIF is_cell-icon = abap_true.
      result = alv_icon_html( is_cell-text ).
    ELSEIF is_cell-symbol = abap_true.
      result = alv_symbol_html( is_cell-text ).
    ELSE.
      result = cl_gui_control=>escape_html( is_cell-text ).
    ENDIF.
  ENDMETHOD.

  METHOD render_aggregate_row.
    DATA lv_total TYPE decfloat34.
    DATA lv_total_decimals TYPE i.
    DATA lv_total_sample TYPE string.
    DATA lv_value TYPE string.
    DATA lv_is_subtotal TYPE abap_bool.
    DATA lv_cell_state_class TYPE string.
    DATA lv_data_subtotal TYPE string.

    lv_is_subtotal = xsdbool( iv_subtotal_field IS NOT INITIAL ).
    IF lv_is_subtotal = abap_true.
      result = |<tr class="gg-grid-subtotal gg-state-subtotal" data-subtotal-field="{ cl_gui_control=>escape_html( CONV string( iv_subtotal_field ) ) }" data-subtotal-value="{ cl_gui_control=>escape_html( iv_subtotal_value ) }"><th scope="row">Subtotal</th>|.
    ELSE.
      result = '<tr class="gg-grid-total gg-state-total"><th scope="row">Total</th>'.
    ENDIF.
    LOOP AT mt_fieldcatalog INTO DATA(ls_fieldcat).
      IF ls_fieldcat-no_out IS NOT INITIAL OR ls_fieldcat-tech IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      CLEAR lv_value.
      IF lv_is_subtotal = abap_true
          AND ls_fieldcat-fieldname = iv_subtotal_field.
        lv_value = iv_subtotal_value.
      ELSEIF ls_fieldcat-do_sum = 'X'.
        CLEAR: lv_total, lv_total_sample.
        LOOP AT it_rows INTO DATA(ls_row).
          READ TABLE ls_row-cells INTO DATA(ls_cell)
            WITH KEY fieldname = ls_fieldcat-fieldname.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
          IF lv_total_sample IS INITIAL.
            lv_total_sample = ls_cell-text.
          ENDIF.
          TRY.
              lv_total = lv_total + CONV decfloat34( ls_cell-text ).
            CATCH cx_root.
              CONTINUE.
          ENDTRY.
        ENDLOOP.
        IF ls_fieldcat-qfieldname IS NOT INITIAL.
          lv_total_decimals = 0.
        ELSEIF ls_fieldcat-decimals_o IS NOT INITIAL.
          lv_total_decimals = CONV i( ls_fieldcat-decimals_o ).
        ELSE.
          lv_total_decimals = -1.
        ENDIF.
        lv_value = cl_gui_control=>format_total_value(
          iv_value    = lv_total
          iv_decimals = lv_total_decimals
          iv_sample   = lv_total_sample ).
      ELSE.
        lv_value = '-'.
      ENDIF.
      lv_cell_state_class = cl_gui_control=>state_class(
        iv_total    = xsdbool( lv_is_subtotal = abap_false )
        iv_subtotal = lv_is_subtotal ).
      lv_data_subtotal = COND string(
        WHEN lv_is_subtotal = abap_true THEN 'true'
        ELSE 'false' ).
      result = result && |<td class="gg-grid-cell { lv_cell_state_class } gg-grid-total-cell" data-subtotal="{ lv_data_subtotal }" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }">{ cl_gui_control=>escape_html( lv_value ) }</td>|.
    ENDLOOP.
    result = result && '</tr>'.
  ENDMETHOD.

  METHOD render_model.
    DATA lv_has_total TYPE abap_bool.
    DATA lv_subtotal_field TYPE lvc_fname.
    DATA lv_subtotal_value TYPE string.
    DATA lt_subtotal_rows TYPE ty_html_rows.
    DATA ls_subtotal_sort TYPE lvc_s_sort.
    DATA lv_toolbar TYPE string.

    lv_has_total = xsdbool( line_exists( mt_fieldcatalog[ do_sum = 'X' ] ) ).
    READ TABLE mt_sort INTO ls_subtotal_sort WITH KEY subtot = 'X'.
    IF sy-subrc = 0.
      lv_subtotal_field = ls_subtotal_sort-fieldname.
    ENDIF.
    lv_toolbar = '<div class="gg-alv-toolbar" role="toolbar" aria-label="ALV toolbar" data-toolbar-scope="control">'.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&REFRESH" title="Refresh" aria-label="Refresh">{ zcl_gg_host_icons=>icon( iv_name = 'refresh' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&SORT_ASC" title="Sort ascending" aria-label="Sort ascending">{ zcl_gg_host_icons=>icon( iv_name = 'arrow-bar-to-up' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&SORT_DSC" title="Sort descending" aria-label="Sort descending">{ zcl_gg_host_icons=>icon( iv_name = 'arrow-bar-to-down' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&FIND" title="Find" aria-label="Find">{ zcl_gg_host_icons=>icon( iv_name = 'search' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&FILTER" title="Filter" aria-label="Filter">{ zcl_gg_host_icons=>icon( iv_name = 'search-plus' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&SUMC" title="Sum" aria-label="Sum">{ zcl_gg_host_icons=>icon( iv_name = 'database' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&SUBTOT" title="Subtotals" aria-label="Subtotals">{ zcl_gg_host_icons=>icon( iv_name = 'folder' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&PRINT" title="Print" aria-label="Print">{ zcl_gg_host_icons=>icon( iv_name = 'printer' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&XML" title="XML export" aria-label="XML export">{ zcl_gg_host_icons=>icon( iv_name = 'file-arrow-down' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&PC" title="Export to file" aria-label="Export to file">{ zcl_gg_host_icons=>icon( iv_name = 'file-arrow-down' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&SAVE" title="Save variant" aria-label="Save variant">{ zcl_gg_host_icons=>icon( iv_name = 'device-floppy' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&LOAD" title="Load variant" aria-label="Load variant">{ zcl_gg_host_icons=>icon( iv_name = 'folder-open' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&VIEW" title="Change layout" aria-label="Change layout">{ zcl_gg_host_icons=>icon( iv_name = 'screen' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&ALL" title="Select all" aria-label="Select all">{ zcl_gg_host_icons=>icon( iv_name = 'circle-check' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&LOCAL&APPEND" title="Insert row" aria-label="Insert row">{ zcl_gg_host_icons=>icon( iv_name = 'plus' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&LOCAL&DELETE_ROW" title="Delete row" aria-label="Delete row">{ zcl_gg_host_icons=>icon( iv_name = 'trash' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&UNDO" title="Undo" aria-label="Undo">{ zcl_gg_host_icons=>icon( iv_name = 'arrow-back-up' ) }</button>|.
    lv_toolbar = lv_toolbar && |<button class="gg-alv-tool-button" type="submit" name="gg_ucomm" value="&HELP" title="Help" aria-label="Help">{ zcl_gg_host_icons=>icon( iv_name = 'help-circle' ) }</button>|.
    lv_toolbar = lv_toolbar && '</div>'.
    result = |<section class="gg-alv" aria-label="ALV grid"><header><h2>{ cl_gui_control=>escape_html( CONV string( mv_gridtitle ) ) }</h2></header>{ COND string( WHEN mv_toolbar_visible = abap_true THEN lv_toolbar ELSE `` ) }<table data-sortable="true" data-field-count="{ lines( mt_fieldcatalog ) }" data-ready-for-input="{ mv_ready_for_input }" data-filtered-rows="{ lines( mt_filtered_entries ) }" data-variant="{ cl_gui_control=>escape_html( CONV string( ms_variant-variant ) ) }"><thead><tr><th scope="col">Select</th>|.
    LOOP AT mt_fieldcatalog INTO DATA(ls_fieldcat).
      IF ls_fieldcat-no_out IS INITIAL AND ls_fieldcat-tech IS INITIAL.
        DATA(lv_heading) = ls_fieldcat-coltext.
        IF lv_heading IS INITIAL.
          lv_heading = ls_fieldcat-scrtext_l.
        ENDIF.
        IF lv_heading IS INITIAL.
          lv_heading = ls_fieldcat-fieldname.
        ENDIF.
        result = result && |<th class="gg-grid-column { cl_gui_control=>state_class( iv_total = xsdbool( ls_fieldcat-do_sum = 'X' ) ) }" scope="col" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }" data-inttype="{ cl_gui_control=>escape_html( CONV string( ls_fieldcat-inttype ) ) }" data-sortable="true">{ cl_gui_control=>escape_html( CONV string( lv_heading ) ) }</th>|.
      ENDIF.
    ENDLOOP.
    result = result && |</tr></thead><tbody>|.
    LOOP AT mt_html_rows INTO DATA(ls_row).
      IF lv_subtotal_field IS NOT INITIAL.
        READ TABLE ls_row-cells INTO DATA(ls_subtotal_cell)
          WITH KEY fieldname = lv_subtotal_field.
        IF sy-subrc = 0.
          IF lt_subtotal_rows IS NOT INITIAL
              AND ls_subtotal_cell-text <> lv_subtotal_value.
            result = result && render_aggregate_row(
              it_rows           = lt_subtotal_rows
              iv_subtotal_field = lv_subtotal_field
              iv_subtotal_value = lv_subtotal_value ).
            CLEAR lt_subtotal_rows.
          ENDIF.
          lv_subtotal_value = ls_subtotal_cell-text.
          APPEND ls_row TO lt_subtotal_rows.
        ENDIF.
      ENDIF.
      DATA(lv_selected) = xsdbool( line_exists( mt_selected_rows[ index = ls_row-index ] ) ).
      DATA(lv_row_state_class) = cl_gui_control=>state_class( iv_selected = lv_selected ).
      DATA(lv_row_color_attr) = COND string(
        WHEN ls_row-color_style IS INITIAL THEN ``
        ELSE | style="{ ls_row-color_style }" data-lvc-color="{ cl_gui_control=>escape_html( ls_row-color_code ) }"| ).
      result = result && |<tr class="gg-grid-row { lv_row_state_class }" data-row-index="{ ls_row-index }" data-lvc-color="{ cl_gui_control=>escape_html( ls_row-color_code ) }" aria-selected="{ COND string( WHEN lv_selected = abap_true THEN `true` ELSE `false` ) }"{ COND string( WHEN lv_selected = abap_true THEN ` selected` ELSE `` ) }{ lv_row_color_attr }><td class="gg-grid-cell { cl_gui_control=>state_class( iv_selected = lv_selected ) }" style="{ ls_row-color_style }"><input class="{ cl_gui_control=>state_class( iv_selected = lv_selected ) }" type="checkbox" name="gg-alv-row-{ ls_row-index }" aria-label="Select row { ls_row-index }" value="{ ls_row-index }"{ COND string( WHEN lv_selected = abap_true THEN ` checked` ELSE `` ) }></td>|.
      LOOP AT ls_row-cells INTO DATA(ls_cell).
        result = result && render_cell(
          is_row  = ls_row
          is_cell = ls_cell ).
      ENDLOOP.
      result = result && |</tr>|.
    ENDLOOP.
    IF lt_subtotal_rows IS NOT INITIAL.
      result = result && render_aggregate_row(
        it_rows           = lt_subtotal_rows
        iv_subtotal_field = lv_subtotal_field
        iv_subtotal_value = lv_subtotal_value ).
    ENDIF.
    result = result && |</tbody>|.
    IF lv_has_total = abap_true.
      result = result && '<tfoot>' && render_aggregate_row( it_rows = mt_html_rows ) && '</tfoot>'.
    ENDIF.
    result = result && |</table></section>|.
  ENDMETHOD.

  METHOD get_selected_rows.
    et_index_rows = mt_selected_rows.
    et_row_no = mt_selected_rows.
  ENDMETHOD.

ENDCLASS.
