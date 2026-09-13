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
             fieldname  TYPE lvc_fname,
             text       TYPE string,
             type_class TYPE string,
             editable   TYPE abap_bool,
             checkbox   TYPE abap_bool,
             f4         TYPE abap_bool,
             dropdown   TYPE i,
             total      TYPE abap_bool,
             subtotal   TYPE abap_bool,
             hotspot    TYPE abap_bool,
           END OF ty_html_cell.
    TYPES ty_html_cells TYPE STANDARD TABLE OF ty_html_cell WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_html_row,
             index TYPE i,
             cells TYPE ty_html_cells,
           END OF ty_html_row.
    TYPES ty_html_rows TYPE STANDARD TABLE OF ty_html_row WITH DEFAULT KEY.
    DATA mt_fieldcatalog TYPE lvc_t_fcat.
    DATA mt_html_rows TYPE ty_html_rows.
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
    cl_gui_control=>set_payload(
      control = me
      payload = |ALV border={ border }; rows={ lines( mt_html_rows ) }| ).
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
    refresh_table_display( ).
  ENDMETHOD.

  METHOD get_filtered_entries.
    et_filtered_entries = mt_filtered_entries.
  ENDMETHOD.

  METHOD set_filter_criteria.
    mt_filter = it_filter.
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

  METHOD set_table_for_first_display.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.
    DATA ls_row TYPE ty_html_row.
    DATA ls_fieldcat TYPE lvc_s_fcat.
    DATA lv_has_component TYPE abap_bool.

    CLEAR mt_html_rows.
    CLEAR mt_fieldcatalog.
    IF it_fieldcatalog IS SUPPLIED.
      mt_fieldcatalog = it_fieldcatalog.
    ENDIF.
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
              DATA(lv_cell_raw) = |{ <component> }|.
              DATA(lv_cell_text) = cl_gui_control=>format_external_value(
                iv_value = lv_cell_raw
                iv_type  = CONV string( ls_fieldcat-inttype ) ).
              APPEND VALUE #( fieldname  = ls_fieldcat-fieldname
                              text       = lv_cell_text
                              type_class = COND string(
                                WHEN ls_fieldcat-inttype = 'I'
                                  OR ls_fieldcat-inttype = 'P'
                                  OR ls_fieldcat-inttype = 'N'
                                  OR ls_fieldcat-inttype = 'F'
                                  THEN `gg-type-number`
                                WHEN ls_fieldcat-inttype = 'D' THEN `gg-type-date`
                                WHEN ls_fieldcat-inttype = 'T' THEN `gg-type-time`
                                ELSE `gg-type-text` )
                              editable   = xsdbool( ls_fieldcat-edit = 'X' )
                              checkbox   = xsdbool( ls_fieldcat-checkbox = 'X' )
                              f4         = xsdbool( ls_fieldcat-f4availabl = 'X' )
                              dropdown   = ls_fieldcat-drdn_hndl
                              total      = xsdbool( ls_fieldcat-do_sum = 'X' )
                              hotspot    = xsdbool( ls_fieldcat-hotspot = 'X' ) ) TO ls_row-cells.
              lv_has_component = abap_true.
            ENDIF.
          ENDIF.
        ENDLOOP.
        IF lv_has_component = abap_false.
          READ TABLE mt_fieldcatalog INTO ls_fieldcat INDEX 1.
          IF sy-subrc = 0.
            DATA(lv_row_text) = cl_gui_control=>format_external_value(
              iv_value = |{ <row> }|
              iv_type  = CONV string( ls_fieldcat-inttype ) ).
            APPEND VALUE #( fieldname  = ls_fieldcat-fieldname
                            text       = lv_row_text
                            type_class = COND string(
                              WHEN ls_fieldcat-inttype = 'I'
                                OR ls_fieldcat-inttype = 'P'
                                OR ls_fieldcat-inttype = 'N'
                                OR ls_fieldcat-inttype = 'F'
                                THEN `gg-type-number`
                              WHEN ls_fieldcat-inttype = 'D' THEN `gg-type-date`
                              WHEN ls_fieldcat-inttype = 'T' THEN `gg-type-time`
                              ELSE `gg-type-text` )
                            editable   = xsdbool( ls_fieldcat-edit = 'X' )
                            checkbox   = xsdbool( ls_fieldcat-checkbox = 'X' )
                            f4         = xsdbool( ls_fieldcat-f4availabl = 'X' )
                            dropdown   = ls_fieldcat-drdn_hndl
                            total      = xsdbool( ls_fieldcat-do_sum = 'X' )
                            hotspot    = xsdbool( ls_fieldcat-hotspot = 'X' ) ) TO ls_row-cells.
          ENDIF.
        ENDIF.
      ENDIF.
      APPEND ls_row TO mt_html_rows.
    ENDLOOP.
    cl_gui_control=>set_payload(
      control = me
      payload = |ALV rows: { lines( mt_html_rows ) }| ).
    cl_gui_control=>set_html(
      control = me
      html    = render_model( ) ).
  ENDMETHOD.

  METHOD render_model.
    result = |<section class="gg-alv" aria-label="ALV grid"><header><h2>{ cl_gui_control=>escape_html( CONV string( mv_gridtitle ) ) }</h2></header>{ COND string( WHEN mv_toolbar_visible = abap_true THEN `<div class="gg-alv-toolbar" role="toolbar" aria-label="ALV toolbar" data-toolbar-scope="control"><button type="submit" name="gg_ucomm" value="&REFRESH">Refresh</button><button type="submit" name="gg_ucomm" value="&SORT">Sort</button><button type="submit" name="gg_ucomm" value="&FILTER">Filter</button></div>` ELSE `` ) }<table data-sortable="true"><thead><tr><th scope="col">Select</th>|.
    LOOP AT mt_fieldcatalog INTO DATA(ls_fieldcat).
      IF ls_fieldcat-no_out IS INITIAL AND ls_fieldcat-tech IS INITIAL.
        DATA(lv_heading) = ls_fieldcat-coltext.
        IF lv_heading IS INITIAL.
          lv_heading = ls_fieldcat-scrtext_l.
        ENDIF.
        IF lv_heading IS INITIAL.
          lv_heading = ls_fieldcat-fieldname.
        ENDIF.
        result = result && |<th class="gg-grid-column { cl_gui_control=>state_class( iv_total = xsdbool( ls_fieldcat-do_sum = 'X' ) ) }" scope="col" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_fieldcat-fieldname ) ) }" data-sortable="true">{ cl_gui_control=>escape_html( CONV string( lv_heading ) ) }</th>|.
      ENDIF.
    ENDLOOP.
    result = result && |</tr></thead><tbody>|.
    LOOP AT mt_html_rows INTO DATA(ls_row).
      DATA(lv_selected) = xsdbool( line_exists( mt_selected_rows[ index = ls_row-index ] ) ).
      DATA(lv_row_state_class) = cl_gui_control=>state_class( iv_selected = lv_selected ).
      result = result && |<tr class="gg-grid-row { lv_row_state_class }" data-row-index="{ ls_row-index }" aria-selected="{ COND string( WHEN lv_selected = abap_true THEN `true` ELSE `false` ) }"{ COND string( WHEN lv_selected = abap_true THEN ` selected` ELSE `` ) }><td class="gg-grid-cell { cl_gui_control=>state_class( iv_selected = lv_selected ) }"><input class="{ cl_gui_control=>state_class( iv_selected = lv_selected ) }" type="checkbox" name="gg-alv-row-{ ls_row-index }" aria-label="Select row { ls_row-index }" value="{ ls_row-index }"{ COND string( WHEN lv_selected = abap_true THEN ` checked` ELSE `` ) }></td>|.
      LOOP AT ls_row-cells INTO DATA(ls_cell).
        DATA(lv_cell_state_class) = cl_gui_control=>state_class(
          iv_total    = ls_cell-total
          iv_subtotal = ls_cell-subtotal
          iv_hotspot  = ls_cell-hotspot
          iv_readonly = xsdbool( ls_cell-editable = abap_false ) ).
        result = result && |<td class="gg-grid-cell { lv_cell_state_class } { ls_cell-type_class }" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) }">|.
        IF ls_cell-dropdown > 0.
          result = result && |<select name="gg-alv-cell-{ ls_row-index }-{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) }" aria-label="{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) } row { ls_row-index }">|.
          LOOP AT mt_drop_down INTO DATA(ls_drop) WHERE handle = ls_cell-dropdown.
            result = result && |<option value="{ cl_gui_control=>escape_html( CONV string( ls_drop-value ) ) }"{ COND string( WHEN ls_drop-value = ls_cell-text THEN ` selected` ELSE `` ) }>{ cl_gui_control=>escape_html( CONV string( ls_drop-value ) ) }</option>|.
          ENDLOOP.
          result = result && |</select>|.
        ELSEIF ls_cell-checkbox = abap_true.
          result = result && |<input type="checkbox" name="gg-alv-cell-{ ls_row-index }-{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) }" aria-label="{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) } row { ls_row-index }"{ COND string( WHEN ls_cell-text = 'X' OR ls_cell-text = '1' THEN ` checked` ELSE `` ) }>|.
        ELSEIF ls_cell-editable = abap_true.
          result = result && |<input type="text" name="gg-alv-cell-{ ls_row-index }-{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) }" value="{ cl_gui_control=>escape_html( ls_cell-text ) }" aria-label="{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) } row { ls_row-index }">|.
        ELSEIF ls_cell-hotspot = abap_true.
          result = result && |<button type="submit" name="gg_action" value="COMMAND:ALV-HOTSPOT-{ ls_row-index }-{ cl_gui_control=>escape_html( CONV string( ls_cell-fieldname ) ) }">{ cl_gui_control=>escape_html( ls_cell-text ) }</button>|.
        ELSE.
          result = result && cl_gui_control=>escape_html( ls_cell-text ).
        ENDIF.
        result = result && |</td>|.
      ENDLOOP.
      result = result && |</tr>|.
    ENDLOOP.
    result = result && |</tbody></table></section>|.
  ENDMETHOD.

  METHOD get_selected_rows.
    et_index_rows = mt_selected_rows.
    et_row_no = mt_selected_rows.
  ENDMETHOD.

ENDCLASS.
