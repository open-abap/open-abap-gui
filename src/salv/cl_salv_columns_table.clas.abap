CLASS cl_salv_columns_table DEFINITION PUBLIC INHERITING FROM cl_salv_columns_list.
  PUBLIC SECTION.
    METHODS set_cell_type_column
      IMPORTING value TYPE string.
    METHODS set_color_column
      IMPORTING value TYPE string.
    METHODS set_exception_column
      IMPORTING value TYPE any.
    METHODS set_hyperlink_entry_column
      IMPORTING
        value TYPE any.
    METHODS get_color_column
      RETURNING
        VALUE(value) TYPE lvc_fname.
    METHODS get_exception_column
      RETURNING
        VALUE(value) TYPE lvc_fname.

  PROTECTED SECTION.
    METHODS create_column REDEFINITION.

  PRIVATE SECTION.
    DATA mv_color_column TYPE lvc_fname.
    DATA mv_exception_column TYPE lvc_fname.
ENDCLASS.

CLASS cl_salv_columns_table IMPLEMENTATION.
  METHOD create_column.
    value = NEW cl_salv_column_table( columnname = columnname ).
  ENDMETHOD.

  METHOD set_hyperlink_entry_column.
    TRY.
        get_column( CONV lvc_fname( value ) )->set_technical( abap_true ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD get_color_column.
    value = mv_color_column.
  ENDMETHOD.

  METHOD get_exception_column.
    value = mv_exception_column.
  ENDMETHOD.

  METHOD set_exception_column.
* The exception column stays on screen; the grid shows its values as lights.
    mv_exception_column = CONV lvc_fname( value ).
  ENDMETHOD.

  METHOD set_cell_type_column.
    TRY.
        get_column( CONV lvc_fname( value ) )->set_technical( abap_true ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD set_color_column.
    mv_color_column = CONV lvc_fname( value ).
    TRY.
        get_column( CONV lvc_fname( value ) )->set_technical( abap_true ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
