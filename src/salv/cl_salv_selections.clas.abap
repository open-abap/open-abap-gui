CLASS cl_salv_selections DEFINITION PUBLIC.
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

ENDCLASS.

CLASS cl_salv_selections IMPLEMENTATION.

  METHOD get_selection_mode.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selection_mode.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_rows.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_rows.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selected_cells.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_cells.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_current_cell.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_current_cell.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
