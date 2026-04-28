CLASS cl_salv_column_list DEFINITION PUBLIC INHERITING FROM cl_salv_column.
  PUBLIC SECTION.
    METHODS set_icon
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_cell_type
      IMPORTING
        value TYPE any OPTIONAL.

    METHODS set_key
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_color
      IMPORTING
        value TYPE lvc_s_colo.
ENDCLASS.

CLASS cl_salv_column_list IMPLEMENTATION.
  METHOD set_color.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_key.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_cell_type.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_icon.
    RETURN. " todo, implement method
  ENDMETHOD.
ENDCLASS.