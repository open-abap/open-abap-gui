CLASS cl_gui_alv_grid DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS free.

    METHODS set_table_for_first_display
      IMPORTING
        i_buffer_active TYPE any OPTIONAL
        i_bypassing_buffer TYPE abap_bool OPTIONAL
        i_consistency_check TYPE abap_bool OPTIONAL
        i_structure_name TYPE any OPTIONAL
        is_variant TYPE any OPTIONAL
        i_save TYPE abap_bool OPTIONAL
        i_default TYPE abap_bool DEFAULT 'X'
        is_layout TYPE any OPTIONAL
        is_print TYPE any OPTIONAL
        it_special_groups TYPE any OPTIONAL
        it_toolbar_excluding TYPE any OPTIONAL
        it_hyperlink TYPE any OPTIONAL
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
ENDCLASS.

CLASS cl_gui_alv_grid IMPLEMENTATION.

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