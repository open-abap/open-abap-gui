CLASS cl_salv_columns_table DEFINITION PUBLIC INHERITING FROM cl_salv_columns_list.
  PUBLIC SECTION.
    METHODS set_cell_type_column
      IMPORTING value TYPE string.
    METHODS set_color_column
      IMPORTING value TYPE string.
    METHODS get
      RETURNING VALUE(value) TYPE string.
    METHODS set_exception_column
      IMPORTING value TYPE any.
    METHODS set_hyperlink_entry_column
      IMPORTING
        value TYPE any.
ENDCLASS.

CLASS cl_salv_columns_table IMPLEMENTATION.
  METHOD set_hyperlink_entry_column.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_exception_column.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_cell_type_column.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_color_column.
    ASSERT 1 = 'todo'.
  ENDMETHOD.
ENDCLASS.