CLASS cl_gui_alv_grid_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
  PROTECTED SECTION.
    METHODS set_delay_change_selection
      IMPORTING
        time TYPE i
      EXCEPTIONS
        error.
ENDCLASS.

CLASS cl_gui_alv_grid_base IMPLEMENTATION.
  METHOD set_delay_change_selection.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.