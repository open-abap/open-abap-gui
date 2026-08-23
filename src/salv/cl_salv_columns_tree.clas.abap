CLASS cl_salv_columns_tree DEFINITION PUBLIC INHERITING FROM cl_salv_columns.
  PUBLIC SECTION.

    METHODS set_exception_column
      IMPORTING
        value TYPE lvc_fname
        group TYPE salv_de_constant DEFAULT 0
      RAISING
        cx_salv_data_error.

    METHODS get_exception_column
      RETURNING
        VALUE(value) TYPE lvc_fname.

ENDCLASS.

CLASS cl_salv_columns_tree IMPLEMENTATION.

  METHOD set_exception_column.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_exception_column.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
