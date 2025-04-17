CLASS cl_salv_column_table DEFINITION PUBLIC INHERITING FROM cl_salv_column_list.
  PUBLIC SECTION.
    METHODS get_output_length
      RETURNING
        VALUE(length) TYPE i.
ENDCLASS.

CLASS cl_salv_column_table IMPLEMENTATION.
  METHOD get_output_length.
    ASSERT 1 = 'todo'.
  ENDMETHOD.
ENDCLASS.