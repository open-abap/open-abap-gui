CLASS cl_salv_selections DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS set_selection_mode
      IMPORTING
        value TYPE i DEFAULT if_salv_c_selection_mode=>none.

    METHODS set_selected_rows
      IMPORTING
        value TYPE salv_t_row.

    METHODS get_selected_rows
      RETURNING
        VALUE(value) TYPE salv_t_row.
ENDCLASS.

CLASS cl_salv_selections IMPLEMENTATION.
  METHOD get_selected_rows.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selected_rows.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selection_mode.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.