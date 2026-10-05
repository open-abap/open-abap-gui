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

    IF mo_grid IS BOUND.
      mo_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
      mt_selected_rows = VALUE #( FOR ls_row IN lt_rows ( ls_row-index ) ).
    ENDIF.
    value = mt_selected_rows.
  ENDMETHOD.

  METHOD set_selected_rows.
    mt_selected_rows = value.
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
