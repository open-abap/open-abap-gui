CLASS cl_salv_selections DEFINITION PUBLIC FRIENDS cl_salv_table.
  PUBLIC SECTION.

    INTERFACES if_salv_c_selection_mode.

    ALIASES cell FOR if_salv_c_selection_mode~cell.
    ALIASES multiple FOR if_salv_c_selection_mode~multiple.
    ALIASES none FOR if_salv_c_selection_mode~none.
    ALIASES row_column FOR if_salv_c_selection_mode~row_column.
    ALIASES single FOR if_salv_c_selection_mode~single.

    METHODS set_selection_mode
      IMPORTING
        value TYPE i DEFAULT if_salv_c_selection_mode=>none.

    METHODS get_selection_mode
      RETURNING
        VALUE(value) TYPE i.

    METHODS set_selected_rows
      IMPORTING
        value TYPE salv_t_row.

    METHODS get_selected_rows
      RETURNING
        VALUE(value) TYPE salv_t_row.

    METHODS set_selected_columns
      IMPORTING
        value TYPE salv_t_column.

    METHODS get_selected_columns
      RETURNING
        VALUE(value) TYPE salv_t_column.

    METHODS set_selected_cells
      IMPORTING
        value TYPE salv_t_cell.

    METHODS get_selected_cells
      RETURNING
        VALUE(value) TYPE salv_t_cell.

    METHODS set_current_cell
      IMPORTING
        value TYPE salv_s_cell.

    METHODS get_current_cell
      RETURNING
        VALUE(value) TYPE salv_s_cell.

  PRIVATE SECTION.
    DATA mv_selection_mode TYPE i.
    DATA mt_selected_rows TYPE salv_t_row.
    DATA mt_selected_columns TYPE salv_t_column.
    DATA mt_selected_cells TYPE salv_t_cell.
    DATA ms_current_cell TYPE salv_s_cell.
* The grid control of a SALV table in a container; its selection is the
* user's.
    DATA mo_grid TYPE REF TO cl_gui_alv_grid.
    DATA mt_row_map TYPE salv_t_row.

ENDCLASS.

CLASS cl_salv_selections IMPLEMENTATION.

  METHOD get_selection_mode.
    value = mv_selection_mode.
  ENDMETHOD.

  METHOD set_selection_mode.
    mv_selection_mode = value.
  ENDMETHOD.

  METHOD get_selected_rows.
    DATA lt_rows TYPE lvc_t_row.

    IF mo_grid IS BOUND AND mt_row_map IS NOT INITIAL.
      mo_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
      CLEAR mt_selected_rows.
      LOOP AT lt_rows INTO DATA(ls_row).
        READ TABLE mt_row_map INTO DATA(lv_row) INDEX ls_row-index.
        IF sy-subrc = 0.
          APPEND lv_row TO mt_selected_rows.
        ENDIF.
      ENDLOOP.
    ENDIF.
    value = mt_selected_rows.
  ENDMETHOD.

  METHOD set_selected_rows.
    DATA lt_rows TYPE lvc_t_row.
    mt_selected_rows = value.
    IF mo_grid IS BOUND AND mt_row_map IS NOT INITIAL.

      LOOP AT value INTO DATA(lv_selected).
        READ TABLE mt_row_map TRANSPORTING NO FIELDS WITH KEY table_line = lv_selected.
        IF sy-subrc = 0.
          APPEND VALUE #( index = sy-tabix ) TO lt_rows.
        ENDIF.
      ENDLOOP.
      mo_grid->set_selected_rows( it_index_rows = lt_rows ).
    ENDIF.
  ENDMETHOD.

  METHOD get_selected_columns.
    value = mt_selected_columns.
  ENDMETHOD.

  METHOD set_selected_columns.
    mt_selected_columns = value.
  ENDMETHOD.

  METHOD get_selected_cells.
    value = mt_selected_cells.
  ENDMETHOD.

  METHOD set_selected_cells.
    mt_selected_cells = value.
  ENDMETHOD.

  METHOD get_current_cell.
    value = ms_current_cell.
  ENDMETHOD.

  METHOD set_current_cell.
    ms_current_cell = value.
  ENDMETHOD.

ENDCLASS.
