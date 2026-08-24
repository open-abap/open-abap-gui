CLASS cl_salv_columns_hierseq DEFINITION PUBLIC INHERITING FROM cl_salv_columns_list.
  PUBLIC SECTION.

    METHODS set_expand_column
      IMPORTING
        value TYPE lvc_fname
      RAISING
        cx_salv_data_error.

    METHODS get_expand_column
      RETURNING
        VALUE(value) TYPE lvc_fname.

ENDCLASS.

CLASS cl_salv_columns_hierseq IMPLEMENTATION.

  METHOD set_expand_column.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_expand_column.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
