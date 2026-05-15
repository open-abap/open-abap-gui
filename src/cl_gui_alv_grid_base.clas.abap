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
ENDCLASS.

CLASS cl_gui_alv_grid_base IMPLEMENTATION.
  METHOD set_delay_change_selection.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.