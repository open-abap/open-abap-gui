CLASS cl_gui_alv_grid DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        i_parent TYPE REF TO cl_gui_container.

    METHODS free.

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
        it_hyperlink    TYPE any OPTIONAL
        it_alv_graphics TYPE any OPTIONAL
        it_except_qinfo TYPE any OPTIONAL
        ir_salv_adapter TYPE REF TO any OPTIONAL
      CHANGING
        it_outtab       TYPE STANDARD TABLE
        it_fieldcatalog TYPE any OPTIONAL
        it_sort         TYPE any OPTIONAL
        it_filter       TYPE any OPTIONAL
      EXCEPTIONS
        invalid_parameter_combination
        program_error
        too_many_lines.

    METHODS get_selected_rows
      EXPORTING
        et_index_rows TYPE any
        et_row_no     TYPE any.

    METHODS refresh_table_display
      IMPORTING
        is_stable      TYPE any OPTIONAL
        i_soft_refresh TYPE abap_bool OPTIONAL
      EXCEPTIONS
        finished.

    EVENTS double_click
      EXPORTING
        VALUE(e_row)     TYPE any OPTIONAL
        VALUE(e_column)  TYPE any OPTIONAL
        VALUE(es_row_no) TYPE any OPTIONAL.

    EVENTS user_command
      EXPORTING
        VALUE(e_ucomm) TYPE sy-ucomm OPTIONAL.

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

    CONSTANTS mc_fc_loc_copy_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_delete_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_append_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_insert_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_move_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_copy TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_cut TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_paste TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_paste_new_row TYPE ui_func VALUE 'TODO'.
    CONSTANTS mc_fc_loc_undo TYPE ui_func VALUE 'TODO'.
ENDCLASS.

CLASS cl_gui_alv_grid IMPLEMENTATION.

  METHOD constructor.
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