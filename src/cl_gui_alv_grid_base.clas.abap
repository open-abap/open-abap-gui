CLASS cl_gui_alv_grid_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
  PROTECTED SECTION.
    EVENTS click_col_header
      EXPORTING
        VALUE(col_id) TYPE c OPTIONAL.

    METHODS set_delay_change_selection
      IMPORTING
        time TYPE i
      EXCEPTIONS
        error.

    METHODS set_delay_move_current_cell
      IMPORTING
        time TYPE i
      EXCEPTIONS
        error.

    METHODS set_toolbar_visible
      IMPORTING
        visible TYPE any.

    EVENTS toolbar_menu_selected
      EXPORTING
        VALUE(fcode) TYPE c OPTIONAL.

    EVENTS context_menu_selected
      EXPORTING
        VALUE(fcode) TYPE c OPTIONAL.

    EVENTS click_row_col
      EXPORTING
        VALUE(row_id) TYPE c OPTIONAL
        VALUE(col_id) TYPE c OPTIONAL.

    EVENTS dblclick_row_col
      EXPORTING
        VALUE(row_id) TYPE c OPTIONAL
        VALUE(col_id) TYPE c OPTIONAL.

    EVENTS total_click_row_col
      EXPORTING
        VALUE(row_id) TYPE c OPTIONAL
        VALUE(col_id) TYPE c OPTIONAL.

    EVENTS double_click_col_separator
      EXPORTING
        VALUE(col_id) TYPE c OPTIONAL.

    EVENTS toolbar_button_click
      EXPORTING
        VALUE(fcode) TYPE c OPTIONAL.

    EVENTS toolbar_menubutton_click
      EXPORTING
        VALUE(fcode)      TYPE c OPTIONAL
        VALUE(menu_pos_x) TYPE i OPTIONAL
        VALUE(menu_pos_y) TYPE i OPTIONAL.

    EVENTS drop_external_files
      EXPORTING
        VALUE(files) TYPE c OPTIONAL.

    EVENTS _request_data
      EXPORTING
        VALUE(fragments) TYPE c OPTIONAL.

    EVENTS delayed_move_current_cell.

    EVENTS delayed_change_selection.

    EVENTS context_menu.

    EVENTS f1.
ENDCLASS.

CLASS cl_gui_alv_grid_base IMPLEMENTATION.
  METHOD set_delay_change_selection.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_delay_move_current_cell.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_toolbar_visible.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.