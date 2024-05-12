CLASS cl_salv_column_list DEFINITION PUBLIC INHERITING FROM cl_salv_column.
  PUBLIC SECTION.
    METHODS set_icon
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_cell_type
      IMPORTING
        value TYPE any OPTIONAL.
ENDCLASS.

CLASS cl_salv_column_list IMPLEMENTATION.
  METHOD set_cell_type.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_icon.
    RETURN. " todo, implement method
  ENDMETHOD.
ENDCLASS.