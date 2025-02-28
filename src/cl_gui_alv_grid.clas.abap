CLASS cl_gui_alv_grid DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        i_parent      TYPE REF TO cl_gui_container
        i_appl_events TYPE char1 DEFAULT space.

    METHODS free.

    METHODS set_frontend_layout
      IMPORTING
        is_layout TYPE any.

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

    EVENTS double_click
      EXPORTING
        VALUE(e_row)     TYPE lvc_s_row OPTIONAL
        VALUE(e_column)  TYPE lvc_s_col OPTIONAL
        VALUE(es_row_no) TYPE lvc_s_roid OPTIONAL.

    EVENTS data_changed
      EXPORTING
        VALUE(er_data_changed) TYPE REF TO cl_alv_changed_data_protocol OPTIONAL
        VALUE(e_onf4)          TYPE char1 OPTIONAL
        VALUE(e_onf4_before)   TYPE char1 OPTIONAL
        VALUE(e_onf4_after)    TYPE char1 OPTIONAL
        VALUE(e_ucomm)         TYPE sy-ucomm OPTIONAL.

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

    EVENTS data_changed_finished
      EXPORTING
        VALUE(e_modified) TYPE abap_bool.

    EVENTS context_menu_request
      EXPORTING
        VALUE(e_object) TYPE REF TO cl_ctmenu.

    CLASS-METHODS offline
      RETURNING
        VALUE(e_offline) TYPE i.

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
        et_fieldcatalog TYPE any.

    METHODS get_current_cell
      EXPORTING
        es_row_no TYPE lvc_s_roid
        es_row_id TYPE lvc_s_row
        es_col_id TYPE lvc_s_col.

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

    CONSTANTS mc_fc_check TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_detail TYPE ui_func VALUE 'TODO'.
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
    CONSTANTS mc_fc_refresh TYPE ui_func VALUE 'TODO'.

    CONSTANTS mc_style_enabled TYPE x LENGTH 4 VALUE '00000000'.

    CONSTANTS mc_evt_enter TYPE i VALUE 1.
ENDCLASS.

CLASS cl_gui_alv_grid IMPLEMENTATION.
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

  METHOD free.
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